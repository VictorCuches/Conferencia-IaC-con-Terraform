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
    workspace_key_prefix = "load-balancer"
    encrypt              = true
  }
}

provider "aws" {
  region = var.aws_region
}

# ── Lee los outputs de 1_infra_base desde S3 según el workspace activo ───────
# workspace = terraform.workspace hace que prod lea el state de prod, dev el de dev.
data "terraform_remote_state" "infra" {
  backend = "s3"

  config = {
    bucket               = var.tf_state_bucket
    region               = var.aws_region
    key                  = "terraform.tfstate"
    workspace_key_prefix = "infra-base"
    encrypt              = true
    use_lockfile         = true
  }

  workspace = terraform.workspace
}

locals {
  infra = data.terraform_remote_state.infra.outputs

  # instance_ids viene como mapa { az => id }, lo necesitamos como mapa para for_each
  instance_ids = local.infra.instance_ids
  subnet_ids   = values(local.infra.subnet_ids)
}

# ── Security Group del ALB — solo el ALB acepta tráfico externo ───────────────
resource "aws_security_group" "alb" {
  name        = "${var.project_name}-${terraform.workspace}-alb-sg"
  description = "ALB SG for ${terraform.workspace}"
  vpc_id      = local.infra.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP desde internet"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-${terraform.workspace}-alb-sg" }
}

# ── Application Load Balancer ─────────────────────────────────────────────────
resource "aws_lb" "web" {
  name               = "${var.project_name}-${terraform.workspace}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = local.subnet_ids

  tags = { Name = "${var.project_name}-${terraform.workspace}-alb" }
}

# ── Target Group ──────────────────────────────────────────────────────────────
resource "aws_lb_target_group" "web" {
  name     = "${var.project_name}-${terraform.workspace}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = local.infra.vpc_id

  health_check {
    path                = "/"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 30
    timeout             = 5
    matcher             = "200"
  }

  tags = { Name = "${var.project_name}-${terraform.workspace}-tg" }
}

# ── Adjuntar instancias al Target Group — for_each sobre el mapa del remote state
# dev → 1 attachment  |  prod → 2 attachments. Sin repetir código.
resource "aws_lb_target_group_attachment" "web" {
  for_each = local.instance_ids

  target_group_arn = aws_lb_target_group.web.arn
  target_id        = each.value
  port             = 80
}

# ── Listener: HTTP → forward al Target Group ─────────────────────────────────
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.web.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}
