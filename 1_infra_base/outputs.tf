output "environment" {
  description = "Active workspace / environment"
  value       = terraform.workspace
}

output "instance_type" {
  description = "EC2 instance type used in this environment"
  value       = local.config.instance_type
}

output "instance_ids" {
  description = "IDs of all web instances"
  value       = { for k, v in aws_instance.web : k => v.id }
}

output "public_urls" {
  description = "URLs por AZ — abre cada una en el browser"
  value       = { for az, inst in aws_instance.web : az => "http://${inst.public_ip}" }
}

output "applied_tags" {
  description = "Tags generados con la expresión for (para verificar)"
  value       = local.resource_tags
}

# ── Outputs consumidos por 2_load_balancer via terraform_remote_state ─────────
output "vpc_id" {
  description = "Default VPC ID"
  value       = aws_default_vpc.default.id
}

output "subnet_ids" {
  description = "Subnet ID por AZ — { az => subnet_id }"
  value       = { for az, subnet in aws_default_subnet.az : az => subnet.id }
}

output "security_group_id" {
  description = "Security Group ID de las instancias web"
  value       = aws_security_group.web.id
}
