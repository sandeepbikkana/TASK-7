output "alb_url" {
  description = "Public URL of the Strapi Application Load Balancer"
  value       = "http://${aws_lb.strapi.dns_name}"
}

output "ecs_cluster_name" {
  description = "ECS Cluster name"
  value       = aws_ecs_cluster.sandeep_strapi.name
}

output "ecs_service_name" {
  description = "ECS Service name"
  value       = aws_ecs_service.strapi.name
}

output "rds_endpoint" {
  description = "RDS PostgreSQL endpoint"
  value       = aws_db_instance.sandeep.address
}

output "cloudwatch_log_group" {
  description = "CloudWatch Log Group for ECS"
  value       = aws_cloudwatch_log_group.sandeep_strapi.name
}

output "codedeploy_application" {
  description = "CodeDeploy application name"
  value       = aws_codedeploy_app.ecs.name
}

output "codedeploy_deployment_group" {
  description = "CodeDeploy deployment group name"
  value       = aws_codedeploy_deployment_group.ecs.deployment_group_name
}
