locals {
  # ── Configuración por ambiente ─────────────────────────────────────────────
  env_config = {
    dev = {
      instance_type = "t2.micro"
      color         = "#28a745"
      bg_color      = "#d4edda"
      border_color  = "#c3e6cb"
      replicas      = 1
      label         = "DEVELOPMENT"
    }
    prod = {
      instance_type = "t3.small"
      color         = "#dc3545"
      bg_color      = "#f8d7da"
      border_color  = "#f5c6cb"
      replicas      = 2
      label         = "PRODUCTION"
    }
  }

  config = local.env_config[terraform.workspace]

  # ── FOR expression: construye el mapa de tags desde listas paralelas ───────
  # Evita repetir merge() y llaves manuales; si agregás un tag, solo cambiás las listas.
  tag_keys   = ["Environment", "Project", "ManagedBy", "CostCenter"]
  tag_values = [terraform.workspace, var.project_name, "terraform", "IT-${upper(terraform.workspace)}"]

  resource_tags = { for i, k in local.tag_keys : k => local.tag_values[i] }

  # ── Reglas de ingress como mapa → usado con dynamic for_each en el SG ──────
  sg_ingress_rules = {
    http = {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "HTTP traffic"
    }
    https = {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "HTTPS traffic"
    }
    ssh = {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "SSH access"
    }
  }
}
