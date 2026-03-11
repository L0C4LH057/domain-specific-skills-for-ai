# Infrastructure as Code — Terraform Reference

## Table of Contents
1. [Project Structure](#project-structure)
2. [Module Patterns](#module-patterns)
3. [State Management](#state-management)
4. [AWS Examples](#aws-examples)
5. [Best Practices & Anti-Patterns](#best-practices--anti-patterns)

---

## Project Structure

```
infrastructure/
├── modules/
│   ├── vpc/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── README.md
│   ├── eks/
│   └── rds/
└── environments/
    ├── dev/
    │   ├── main.tf
    │   ├── variables.tf
    │   ├── terraform.tfvars
    │   └── backend.tf
    └── prod/
        ├── main.tf
        ├── variables.tf
        ├── terraform.tfvars
        └── backend.tf
```

---

## Module Patterns

### Module: variables.tf
```hcl
variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be dev, staging, or prod"
  }
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "tags" {
  description = "Common resource tags"
  type        = map(string)
  default     = {}
}
```

### Module: outputs.tf
```hcl
output "vpc_id" {
  description = "ID of the created VPC"
  value       = aws_vpc.main.id
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = aws_subnet.private[*].id
}
```

### Calling a Module
```hcl
module "vpc" {
  source  = "../../modules/vpc"
  # or from Terraform Registry:
  # source  = "terraform-aws-modules/vpc/aws"
  # version = "5.0.0"

  environment = var.environment
  vpc_cidr    = "10.1.0.0/16"

  tags = local.common_tags
}
```

---

## State Management

### Remote State Backend (S3 + DynamoDB)
```hcl
# backend.tf
terraform {
  required_version = ">= 1.7.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "mycompany-terraform-state"
    key            = "prod/myapp/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"   # for state locking
  }
}
```

### Bootstrap State Infrastructure (run once)
```hcl
# state-bootstrap/main.tf
resource "aws_s3_bucket" "terraform_state" {
  bucket = "mycompany-terraform-state"
}

resource "aws_s3_bucket_versioning" "state_versioning" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state_enc" {
  bucket = aws_s3_bucket.terraform_state.id
  rule {
    apply_server_side_encryption_by_default { sse_algorithm = "AES256" }
  }
}

resource "aws_dynamodb_table" "terraform_locks" {
  name         = "terraform-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"
  attribute {
    name = "LockID"
    type = "S"
  }
}
```

---

## AWS Examples

### Complete VPC Module
```hcl
# modules/vpc/main.tf
locals {
  azs = slice(data.aws_availability_zones.available.names, 0, 3)
}

data "aws_availability_zones" "available" { state = "available" }

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = merge(var.tags, { Name = "${var.environment}-vpc" })
}

resource "aws_subnet" "private" {
  count             = length(local.azs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 4, count.index)
  availability_zone = local.azs[count.index]
  tags = merge(var.tags, {
    Name = "${var.environment}-private-${local.azs[count.index]}"
    "kubernetes.io/role/internal-elb" = "1"   # for EKS
  })
}

resource "aws_subnet" "public" {
  count                   = length(local.azs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 4, count.index + 3)
  availability_zone       = local.azs[count.index]
  map_public_ip_on_launch = false    # never auto-assign public IPs
  tags = merge(var.tags, {
    Name = "${var.environment}-public-${local.azs[count.index]}"
    "kubernetes.io/role/elb" = "1"
  })
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags   = merge(var.tags, { Name = "${var.environment}-igw" })
}

resource "aws_eip" "nat" {
  count  = length(local.azs)
  domain = "vpc"
}

resource "aws_nat_gateway" "main" {
  count         = length(local.azs)
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
}
```

### IAM Role with Least Privilege
```hcl
data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }
    condition {
      test     = "StringEquals"
      variable = "${var.oidc_provider}:sub"
      values   = ["system:serviceaccount:${var.namespace}:${var.service_account}"]
    }
  }
}

resource "aws_iam_role" "app" {
  name               = "${var.environment}-${var.app_name}-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy" "app" {
  name = "app-policy"
  role = aws_iam_role.app.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject"]
        Resource = "arn:aws:s3:::${var.bucket_name}/*"
      }
    ]
  })
}
```

---

## Best Practices & Anti-Patterns

### DO
```hcl
# Use locals for repeated expressions
locals {
  common_tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = var.project_name
  }
}

# Use for_each over count for stable state keys
resource "aws_iam_user" "team" {
  for_each = toset(var.team_members)
  name     = each.key
}

# Pin provider versions
terraform {
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
  }
}
```

### DON'T
```hcl
# Never use count for resources that can be added/removed mid-list (causes plan-time drift)
# Never put secrets in .tfvars — use AWS Secrets Manager or Vault data sources
# Never use `:latest` or unversioned module sources
# Never commit terraform.tfstate to git
```

### Workflow
```bash
terraform init              # once per environment / provider change
terraform fmt -recursive    # format before committing
terraform validate          # syntax check
terraform plan -out=tfplan  # always review plan before applying
terraform apply tfplan
terraform destroy           # only for ephemeral environments
```
