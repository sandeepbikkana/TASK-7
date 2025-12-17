output "alb_url" {
  description = "Public URL of Strapi Application Load Balancer"
  value       = "http://${aws_lb.sandeep_strapi.dns_name}"
}

output "rds_endpoint" {
  description = "RDS PostgreSQL endpoint"
  value       = aws_db_instance.sandeep_strapi.address
}

output "log_group_name" {
  description = "CloudWatch Log Group for ECS tasks"
  value       = aws_cloudwatch_log_group.sandeep_strapi.name
}
