output "alb_url" {
  description = "Public URL of the Strapi Application Load Balancer"
  value       = "http://${aws_lb.sandeep_strapi.dns_name}"
}

output "rds_endpoint" {
  description = "RDS PostgreSQL endpoint"
  value       = aws_db_instance.sandeep_strapi.address
}

output "log_group" {
  description = "CloudWatch Log Group"
  value       = aws_cloudwatch_log_group.sandeep_strapi.name
}

output "ecs_cluster_name" {
  description = "ECS Cluster name"
  value       = aws_ecs_cluster.sandeep_strapi.name
}

output "ecs_service_name" {
  description = "ECS Service name"
  value       = aws_ecs_service.sandeep_strapi.name
}

output "cloudwatch_dashboard" {
  description = "CloudWatch Dashboard name"
  value       = aws_cloudwatch_dashboard.sandeep_strapi.dashboard_name
}
