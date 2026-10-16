output "alb_url" {
  description = "URL única del Load Balancer — reemplaza las URLs individuales por AZ"
  value       = "http://${aws_lb.web.dns_name}"
}

output "alb_arn" {
  description = "ARN del ALB"
  value       = aws_lb.web.arn
}

output "target_group_arn" {
  description = "ARN del Target Group"
  value       = aws_lb_target_group.web.arn
}

output "attached_instances" {
  description = "Instancias adjuntas al ALB — leídas desde el remote state de 1_infra_base"
  value       = { for az, id in local.instance_ids : az => id }
}
