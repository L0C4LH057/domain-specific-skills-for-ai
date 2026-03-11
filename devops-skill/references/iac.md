# Infrastructure as Code Reference

## Table of Contents
1. [Terraform](#terraform)
2. [Ansible](#ansible)
3. [Packer](#packer)

---

## Terraform

### Project Structure (Standard)
```
infra/
├── environments/
│   ├── dev/
│   │   ├── main.tf
│   │   ├── terraform.tfvars
│   │   └── backend.tf
│   ├── staging/
│   └── production/
├── modules/
│   ├── vpc/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── eks/
│   └── rds/
└── shared/
    └── locals.tf
```

### backend.tf (Remote State — Always Use)
```hcl
terraform {
  required_version = ">= 1.7.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "my-org-terraform-state"
    key            = "production/main.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"  # Prevents concurrent runs
  }
}
```

### variables.tf Pattern
```hcl
variable "environment" {
  description = "Deployment environment (dev/staging/production)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "environment must be dev, staging, or production."
  }
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
  default     = {}
}
```

### Module: VPC
```hcl
# modules/vpc/main.tf
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.tags, {
    Name = "${var.project}-${var.environment}-vpc"
  })
}

resource "aws_subnet" "public" {
  count             = length(var.availability_zones)
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = merge(var.tags, {
    Name                     = "${var.project}-${var.environment}-public-${count.index + 1}"
    "kubernetes.io/role/elb" = "1"  # For EKS load balancers
  })
}

resource "aws_subnet" "private" {
  count             = length(var.availability_zones)
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 10)
  availability_zone = var.availability_zones[count.index]

  tags = merge(var.tags, {
    Name                              = "${var.project}-${var.environment}-private-${count.index + 1}"
    "kubernetes.io/role/internal-elb" = "1"
  })
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags   = merge(var.tags, { Name = "${var.project}-igw" })
}

resource "aws_nat_gateway" "main" {
  count         = length(var.availability_zones)
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
  tags          = merge(var.tags, { Name = "${var.project}-nat-${count.index + 1}" })
}

resource "aws_eip" "nat" {
  count  = length(var.availability_zones)
  domain = "vpc"
}
```

### outputs.tf Pattern
```hcl
# modules/vpc/outputs.tf
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = aws_subnet.private[*].id
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = aws_subnet.public[*].id
}
```

### locals.tf (Common Tags & Naming)
```hcl
locals {
  common_tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
    Team        = var.team
    CostCenter  = var.cost_center
  }

  name_prefix = "${var.project}-${var.environment}"
}
```

### Terraform Commands
```bash
# Initialize
terraform init -upgrade

# Format & validate
terraform fmt -recursive
terraform validate

# Plan (save plan for reproducible apply)
terraform plan -out=tfplan -var-file=production.tfvars

# Apply saved plan
terraform apply tfplan

# Destroy specific resource
terraform destroy -target=aws_instance.bastion

# Import existing resource
terraform import aws_s3_bucket.assets my-existing-bucket

# State management
terraform state list
terraform state show aws_vpc.main
terraform state mv aws_instance.web aws_instance.app

# Workspace (use environments/ folders instead when possible)
terraform workspace new staging
terraform workspace select production
```

---

## Ansible

### Project Structure
```
ansible/
├── inventory/
│   ├── production/
│   │   ├── hosts.yml
│   │   └── group_vars/
│   │       ├── all.yml
│   │       └── webservers.yml
│   └── staging/
├── playbooks/
│   ├── site.yml          # Master playbook
│   ├── webserver.yml
│   └── database.yml
├── roles/
│   ├── common/
│   │   ├── tasks/main.yml
│   │   ├── handlers/main.yml
│   │   ├── templates/
│   │   ├── files/
│   │   └── defaults/main.yml
│   └── nginx/
└── ansible.cfg
```

### ansible.cfg
```ini
[defaults]
inventory       = inventory/production
remote_user     = ubuntu
private_key_file = ~/.ssh/id_ed25519
host_key_checking = False
roles_path      = ./roles
retry_files_enabled = False
stdout_callback = yaml
collections_path = ./collections

[privilege_escalation]
become      = True
become_method = sudo

[ssh_connection]
pipelining  = True
```

### inventory/production/hosts.yml
```yaml
all:
  children:
    webservers:
      hosts:
        web01:
          ansible_host: 10.0.1.10
        web02:
          ansible_host: 10.0.1.11
    databases:
      hosts:
        db01:
          ansible_host: 10.0.2.10
          db_primary: true
```

### playbooks/site.yml (Master Playbook)
```yaml
---
- name: Apply common configuration
  hosts: all
  roles:
    - common

- name: Configure web servers
  hosts: webservers
  roles:
    - nginx
    - app

- name: Configure databases
  hosts: databases
  roles:
    - postgresql
```

### roles/nginx/tasks/main.yml
```yaml
---
- name: Install nginx
  ansible.builtin.package:
    name: nginx
    state: present
  notify: restart nginx

- name: Deploy nginx config
  ansible.builtin.template:
    src: nginx.conf.j2
    dest: /etc/nginx/nginx.conf
    owner: root
    group: root
    mode: '0644'
    validate: /usr/sbin/nginx -t -c %s
  notify: reload nginx

- name: Ensure nginx is started and enabled
  ansible.builtin.service:
    name: nginx
    state: started
    enabled: true
```

### roles/nginx/handlers/main.yml
```yaml
---
- name: restart nginx
  ansible.builtin.service:
    name: nginx
    state: restarted

- name: reload nginx
  ansible.builtin.service:
    name: nginx
    state: reloaded
```

### Ansible Vault (Encrypt Secrets)
```bash
# Encrypt a file
ansible-vault encrypt group_vars/production/secrets.yml

# Encrypt a single value
ansible-vault encrypt_string 'my_secret_password' --name 'db_password'

# Run playbook with vault
ansible-playbook site.yml --ask-vault-pass
# or
ansible-playbook site.yml --vault-password-file ~/.vault_pass
```

### Ansible Commands
```bash
# Run playbook
ansible-playbook playbooks/site.yml -i inventory/production

# Limit to specific hosts
ansible-playbook playbooks/webserver.yml -l webservers

# Dry run
ansible-playbook playbooks/site.yml --check --diff

# Run single task by tag
ansible-playbook playbooks/site.yml --tags nginx

# Ad-hoc commands
ansible webservers -m ping
ansible webservers -m shell -a "uptime"
ansible webservers -m copy -a "src=./file dest=/tmp/file"
```

---

## Packer

### Build AWS AMI
```hcl
# packer/ubuntu-base.pkr.hcl
packer {
  required_plugins {
    amazon = {
      version = ">= 1.3.0"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

variable "aws_region" {
  default = "us-east-1"
}

variable "app_version" {
  type = string
}

source "amazon-ebs" "ubuntu" {
  region        = var.aws_region
  instance_type = "t3.small"
  source_ami_filter {
    filters = {
      name                = "ubuntu/images/hvm-ssd/ubuntu-22.04-amd64-server-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["099720109477"]  # Canonical
  }
  ssh_username = "ubuntu"
  ami_name     = "my-app-${var.app_version}-{{timestamp}}"
  ami_description = "Baked AMI for my-app v${var.app_version}"
  tags = {
    Base_AMI_Name = "{{ .SourceAMIName }}"
    App_Version   = var.app_version
    ManagedBy     = "packer"
  }
}

build {
  sources = ["source.amazon-ebs.ubuntu"]

  provisioner "shell" {
    inline = [
      "sudo apt-get update -y",
      "sudo apt-get upgrade -y",
      "sudo apt-get install -y curl wget unzip",
    ]
  }

  provisioner "ansible" {
    playbook_file = "./ansible/playbooks/bake-ami.yml"
    extra_arguments = ["--extra-vars", "app_version=${var.app_version}"]
  }
}
```

```bash
# Build AMI
packer build -var="app_version=1.2.3" packer/ubuntu-base.pkr.hcl
```
