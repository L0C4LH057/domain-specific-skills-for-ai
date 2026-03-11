# Cloud Reference — AWS (+ Azure/GCP Notes)

## Table of Contents
1. [AWS IAM Patterns](#aws-iam-patterns)
2. [EKS](#eks)
3. [Networking](#networking)
4. [Lambda / Serverless](#lambda--serverless)
5. [Common AWS CLI Commands](#common-aws-cli-commands)
6. [Azure / GCP Quick Reference](#azure--gcp-quick-reference)

---

## AWS IAM Patterns

### IRSA — IAM Roles for Service Accounts (EKS)
```bash
# Create OIDC provider for the cluster
eksctl utils associate-iam-oidc-provider --cluster my-cluster --approve

# Create role with trust policy scoped to service account
eksctl create iamserviceaccount \
  --cluster my-cluster \
  --namespace production \
  --name myapp-sa \
  --attach-policy-arn arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess \
  --approve
```

### Least-Privilege Policy Template
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowAppBucketAccess",
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject"
      ],
      "Resource": "arn:aws:s3:::mycompany-app-${env}/*"
    },
    {
      "Sid": "AllowListBucket",
      "Effect": "Allow",
      "Action": "s3:ListBucket",
      "Resource": "arn:aws:s3:::mycompany-app-${env}"
    }
  ]
}
```

---

## EKS

### eksctl Cluster Config
```yaml
# cluster.yaml
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig
metadata:
  name: my-cluster
  region: us-east-1
  version: "1.29"

iam:
  withOIDC: true

managedNodeGroups:
  - name: system
    instanceType: t3.medium
    minSize: 2
    maxSize: 4
    desiredCapacity: 2
    privateNetworking: true
    labels:
      role: system
    taints:
      - key: CriticalAddonsOnly
        value: "true"
        effect: NoSchedule

  - name: app
    instanceType: m5.xlarge
    minSize: 2
    maxSize: 20
    desiredCapacity: 3
    privateNetworking: true
    labels:
      role: app
    iam:
      attachPolicyARNs:
        - arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy
        - arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly

addons:
  - name: vpc-cni
    version: latest
  - name: coredns
    version: latest
  - name: kube-proxy
    version: latest
  - name: aws-ebs-csi-driver
    version: latest
    wellKnownPolicies:
      ebsCSIController: true
```

---

## Networking

### VPC Design (3-tier)
```
Public Subnets  (10.0.0.x/24)   → Internet Gateway → ALB, NAT Gateway
Private Subnets (10.0.10.x/24)  → NAT Gateway      → App servers, EKS nodes
DB Subnets      (10.0.20.x/24)  → No internet      → RDS, ElastiCache
```

### Security Group Pattern
```bash
# ALB — open to internet
aws ec2 create-security-group --group-name alb-sg --description "ALB"
aws ec2 authorize-security-group-ingress --group-id sg-alb \
  --protocol tcp --port 443 --cidr 0.0.0.0/0

# App — only from ALB
aws ec2 authorize-security-group-ingress --group-id sg-app \
  --protocol tcp --port 3000 --source-group sg-alb

# DB — only from app
aws ec2 authorize-security-group-ingress --group-id sg-db \
  --protocol tcp --port 5432 --source-group sg-app
```

---

## Lambda / Serverless

### Lambda + API Gateway (Terraform)
```hcl
resource "aws_lambda_function" "api" {
  function_name = "${var.environment}-myapi"
  runtime       = "python3.12"
  handler       = "main.handler"
  role          = aws_iam_role.lambda.arn
  filename      = data.archive_file.lambda_zip.output_path
  timeout       = 30
  memory_size   = 256

  environment {
    variables = {
      ENVIRONMENT = var.environment
      DB_SECRET   = aws_secretsmanager_secret.db.arn
    }
  }

  tracing_config { mode = "Active" }   # X-Ray tracing

  lifecycle { ignore_changes = [filename] }
}

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${aws_lambda_function.api.function_name}"
  retention_in_days = 30
}
```

---

## Common AWS CLI Commands

```bash
# EKS
aws eks update-kubeconfig --name my-cluster --region us-east-1
aws eks list-clusters
aws eks describe-cluster --name my-cluster

# ECR
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin 123456789.dkr.ecr.us-east-1.amazonaws.com
aws ecr describe-repositories
aws ecr list-images --repository-name myapp

# S3
aws s3 ls s3://mybucket/
aws s3 cp ./file.txt s3://mybucket/prefix/
aws s3 sync ./dist s3://mybucket/ --delete

# Secrets Manager
aws secretsmanager get-secret-value --secret-id myapp/production
aws secretsmanager put-secret-value --secret-id myapp/production \
  --secret-string '{"db_password":"newvalue"}'

# SSM Parameter Store
aws ssm get-parameter --name /myapp/prod/db_password --with-decryption
aws ssm put-parameter --name /myapp/prod/db_password \
  --value "secret" --type SecureString --overwrite

# CloudWatch Logs
aws logs tail /aws/lambda/my-function --follow
aws logs filter-log-events --log-group-name /app/myapp \
  --filter-pattern "ERROR" --start-time $(date -d '1 hour ago' +%s)000
```

---

## Azure / GCP Quick Reference

### Azure
```bash
az login
az aks get-credentials --resource-group myRG --name myCluster
az acr login --name myregistry
az keyvault secret show --vault-name myVault --name mySecret
```

### GCP
```bash
gcloud auth login
gcloud container clusters get-credentials my-cluster --zone us-central1-a
gcloud auth configure-docker
gcloud secrets versions access latest --secret=my-secret
```

### Cloud-Agnostic Patterns
| Concept | AWS | Azure | GCP |
|---|---|---|---|
| Kubernetes | EKS | AKS | GKE |
| Container Registry | ECR | ACR | Artifact Registry |
| Secrets | Secrets Manager | Key Vault | Secret Manager |
| Object Storage | S3 | Blob Storage | GCS |
| Serverless | Lambda | Functions | Cloud Run |
| DNS | Route53 | DNS Zone | Cloud DNS |
