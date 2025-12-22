output "alb_url" {
  description = "Public URL of the Strapi Application Load Balancer"
  value       = "http://${aws_lb.sandeep_strapi.dns_name}"
}

output "ecs_cluster_name" {
  description = "ECS Cluster name"
  value       = aws_ecs_cluster.sandeep_strapi.name
}

output "ecs_service_name" {
  description = "ECS Service name"
  value       = aws_ecs_service.sandeep_strapi.name
}

output "rds_endpoint" {
  description = "RDS PostgreSQL endpoint"
  value       = aws_db_instance.sandeep.address
}

output "cloudwatch_log_group" {
  description = "CloudWatch Log Group for ECS Strapi logs"
  value       = aws_cloudwatch_log_group.sandeep_strapi.name
}

output "codedeploy_application_name" {
  description = "CodeDeploy application name"
  value       = aws_codedeploy_app.sandeep.name
}

output "codedeploy_deployment_group_name" {
  description = "CodeDeploy deployment group name"
  value       = aws_codedeploy_deployment_group.sandeep.deployment_group_name
}

output "cloudwatch_dashboard_name" {
  description = "CloudWatch dashboard name for Strapi monitoring"
  value       = aws_cloudwatch_dashboard.sandeep.dashboard_name
}
