terraform {
  required_version = ">= 1.10"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket               = "BUCKET_NAME_FROM_CF_OUTPUT"
    use_lockfile         = true
    region               = "us-east-1"
    key                  = "terraform.tfstate"
    workspace_key_prefix = "infra-base"
    encrypt              = true
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.resource_tags
  }
}

# ── AMI más reciente de Amazon Linux 2023 ─────────────────────────────────────
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# aws_default_vpc adopta la VPC default si existe, o la crea si fue eliminada
resource "aws_default_vpc" "default" {
  tags = { Name = "default" }
}

# AZs disponibles en la región
data "aws_availability_zones" "available" {
  state = "available"
}

# prod usa 2 AZs distintas, dev solo 1. El mismo código, distinto resultado.
resource "aws_default_subnet" "az" {
  for_each          = toset(slice(data.aws_availability_zones.available.names, 0, local.config.replicas)) # dev 1, prod 2
  availability_zone = each.value

  tags = { Name = "default-${each.value}" }
}

# ── Security Group con dynamic for_each sobre el mapa de reglas ───────────────
# Sin for_each habría que escribir un bloque ingress por cada puerto.
resource "aws_security_group" "web" {
  name        = "${var.project_name}-${terraform.workspace}-sg"
  description = "Web SG for ${terraform.workspace}"
  vpc_id      = aws_default_vpc.default.id

  dynamic "ingress" {
    for_each = local.sg_ingress_rules
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
      description = ingress.value.description
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-${terraform.workspace}-sg" }
}

# ── Instancias EC2: for_each sobre nombres de AZ ─────────────────────────────
# Cada instancia vive en una AZ distinta
# prod: ["us-east-1a", "us-east-1b"]  |  dev: ["us-east-1a"]
resource "aws_instance" "web" {
  for_each = toset(slice(data.aws_availability_zones.available.names, 0, local.config.replicas))

  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = local.config.instance_type
  subnet_id              = aws_default_subnet.az[each.key].id
  availability_zone      = each.key
  vpc_security_group_ids = [aws_security_group.web.id]

  user_data = base64encode(templatefile("${path.module}/user_data.sh.tpl", {
    environment   = terraform.workspace
    label         = local.config.label
    color         = local.config.color
    bg_color      = local.config.bg_color
    border_color  = local.config.border_color
    az            = each.key
    replica_count = local.config.replicas
    instance_type = local.config.instance_type
  }))

  tags = {
    Name = "${var.project_name}-${terraform.workspace}-web-${each.key}"
  }
}
