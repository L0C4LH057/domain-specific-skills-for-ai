# Cloud Platforms Reference (AWS / GCP / Azure)

## Table of Contents
1. [AWS](#aws)
2. [GCP](#gcp)
3. [Azure](#azure)
4. [Cloud-Agnostic Patterns](#cloud-agnostic-patterns)

---

## AWS

### EKS Cluster (Terraform)
```hcl
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "${local.name_prefix}-eks"
  cluster_version = "1.29"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids

  cluster_endpoint_public_access = true
  enable_irsa = true  # Enable IAM Roles for Service Accounts

  eks_managed_node_groups = {
    general = {
      instance_types = ["m5.xlarge"]
      min_size       = 2
      max_size       = 10
      desired_size   = 3

      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = 100
            volume_type           = "gp3"
            iops                  = 3000
            throughput            = 125
            encrypted             = true
            delete_on_termination = true
          }
        }
      }

      labels = {
        role = "general"
      }
    }
  }

  tags = local.common_tags
}
```

### RDS (Terraform)
```hcl
module "rds" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 6.0"

  identifier = "${local.name_prefix}-postgres"
  engine     = "postgres"
  engine_version = "16"
  instance_class = "db.t3.medium"

  allocated_storage     = 100
  max_allocated_storage = 500  # Auto-scaling storage
  storage_encrypted     = true

  db_name  = "appdb"
  username = "appuser"
  # Password from Secrets Manager (manage_master_user_password)
  manage_master_user_password = true

  vpc_security_group_ids = [aws_security_group.rds.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name

  multi_az               = true  # HA for production
  deletion_protection    = true
  skip_final_snapshot    = false
  final_snapshot_identifier = "${local.name_prefix}-postgres-final"

  backup_retention_period = 7
  backup_window           = "03:00-04:00"
  maintenance_window      = "Mon:04:00-Mon:05:00"

  performance_insights_enabled = true
  monitoring_interval          = 60  # Enhanced monitoring

  tags = local.common_tags
}
```

### S3 Bucket (Secure)
```hcl
resource "aws_s3_bucket" "assets" {
  bucket = "${local.name_prefix}-assets"
  tags   = local.common_tags
}

resource "aws_s3_bucket_versioning" "assets" {
  bucket = aws_s3_bucket.assets.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "assets" {
  bucket = aws_s3_bucket.assets.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "assets" {
  bucket                  = aws_s3_bucket.assets.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
```

### ALB + Target Group (Terraform)
```hcl
resource "aws_lb" "main" {
  name               = "${local.name_prefix}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = module.vpc.public_subnet_ids

  enable_deletion_protection = true
  drop_invalid_header_fields = true
  tags = local.common_tags
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = aws_acm_certificate.main.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

resource "aws_lb_listener" "http_redirect" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}
```

### AWS CLI Common Commands
```bash
# EKS
aws eks update-kubeconfig --name my-cluster --region us-east-1
aws eks list-clusters

# ECR
aws ecr get-login-password --region us-east-1 \
  | docker login --username AWS --password-stdin 123456789.dkr.ecr.us-east-1.amazonaws.com
aws ecr create-repository --repository-name my-app --image-scanning-configuration scanOnPush=true

# S3
aws s3 cp ./dist s3://my-bucket/dist/ --recursive
aws s3 sync ./dist s3://my-bucket/dist/ --delete

# Secrets Manager
aws secretsmanager get-secret-value --secret-id /production/my-app/db-password \
  --query SecretString --output text

# SSM Parameter Store
aws ssm put-parameter --name "/production/my-app/api-key" \
  --value "my-secret" --type SecureString
aws ssm get-parameter --name "/production/my-app/api-key" --with-decryption
```

---

## GCP

### GKE Cluster (Terraform)
```hcl
resource "google_container_cluster" "main" {
  name     = "${local.name_prefix}-gke"
  location = var.region  # Regional for HA

  remove_default_node_pool = true
  initial_node_count       = 1

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"  # Enable Workload Identity
  }

  addons_config {
    http_load_balancing { disabled = false }
    gce_persistent_disk_csi_driver_config { enabled = true }
  }

  network    = google_compute_network.main.self_link
  subnetwork = google_compute_subnetwork.private.self_link

  ip_allocation_policy {
    cluster_secondary_range_name  = "pod-range"
    services_secondary_range_name = "service-range"
  }

  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = "172.16.0.0/28"
  }
}

resource "google_container_node_pool" "general" {
  name       = "general"
  cluster    = google_container_cluster.main.name
  location   = var.region
  node_count = 1  # Per zone

  autoscaling {
    min_node_count = 1
    max_node_count = 5
  }

  node_config {
    machine_type = "e2-standard-4"
    disk_size_gb = 100
    disk_type    = "pd-ssd"
    spot         = false  # true for cost savings in non-prod

    workload_metadata_config {
      mode = "GKE_METADATA"  # Required for Workload Identity
    }

    oauth_scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }
}
```

### GCP CLI Common Commands
```bash
# Auth
gcloud auth login
gcloud config set project my-project-id

# GKE
gcloud container clusters get-credentials my-cluster --region us-central1

# Cloud Run
gcloud run deploy my-app \
  --image gcr.io/my-project/my-app:latest \
  --region us-central1 \
  --platform managed \
  --allow-unauthenticated \
  --min-instances 1

# Artifact Registry
gcloud auth configure-docker us-central1-docker.pkg.dev
docker push us-central1-docker.pkg.dev/my-project/my-repo/my-app:latest

# Secret Manager
gcloud secrets create my-secret --replication-policy automatic
echo -n "my-value" | gcloud secrets versions add my-secret --data-file=-
gcloud secrets versions access latest --secret my-secret
```

---

## Azure

### AKS Cluster (Terraform)
```hcl
resource "azurerm_kubernetes_cluster" "main" {
  name                = "${local.name_prefix}-aks"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  dns_prefix          = local.name_prefix
  kubernetes_version  = "1.29"

  default_node_pool {
    name                = "system"
    node_count          = 2
    vm_size             = "Standard_D4s_v3"
    os_disk_size_gb     = 100
    vnet_subnet_id      = azurerm_subnet.aks.id
    enable_auto_scaling = true
    min_count           = 2
    max_count           = 10
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin    = "azure"
    network_policy    = "calico"
    load_balancer_sku = "standard"
  }

  oms_agent {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
  }

  tags = local.common_tags
}
```

### Azure CLI Common Commands
```bash
# Login
az login
az account set --subscription my-subscription-id

# AKS
az aks get-credentials --resource-group my-rg --name my-aks

# ACR
az acr login --name myregistry
docker tag myapp myregistry.azurecr.io/myapp:latest
docker push myregistry.azurecr.io/myapp:latest

# Key Vault
az keyvault secret set --vault-name my-vault --name db-password --value "secret"
az keyvault secret show --vault-name my-vault --name db-password --query value -o tsv
```

---

## Cloud-Agnostic Patterns

### Environment Tagging Strategy (Apply to ALL resources)
```hcl
locals {
  common_tags = {
    Project     = var.project       # e.g., "nexacare"
    Environment = var.environment   # dev | staging | production
    ManagedBy   = "terraform"
    Team        = var.team          # e.g., "platform"
    CostCenter  = var.cost_center   # For FinOps
    Owner       = var.owner_email
  }
}
```

### Multi-Region Architecture (DR Pattern)
```
Primary Region (us-east-1):
  - Active EKS cluster
  - RDS Multi-AZ primary
  - S3 with cross-region replication enabled

DR Region (us-west-2):
  - Standby EKS cluster (scaled down or active-active)
  - RDS read replica (promote on failover)
  - S3 replica bucket

DNS Failover:
  - Route53 health checks on primary
  - Failover routing policy → DR region
```

### Cost Optimization Checklist
- [ ] Right-size all instances (use AWS Compute Optimizer / GCP Recommender)
- [ ] Use spot/preemptible instances for non-prod and batch workloads
- [ ] Set up S3/GCS lifecycle policies to archive/delete old objects
- [ ] Enable Reserved Instances or Committed Use for steady-state workloads
- [ ] Tag all resources for cost allocation
- [ ] Set billing alerts at 80% and 100% of budget
- [ ] Use NAT Gateway carefully (expensive at scale — consider VPC endpoints)
