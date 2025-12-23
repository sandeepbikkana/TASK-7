output "alb_dns_name" {
  description = "ALB DNS name"
  value       = aws_lb.sandeep_strapi.dns_name
}

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = aws_ecs_cluster.sandeep_strapi.name
}

output "ecs_service_name" {
  description = "ECS service name"
  value       = aws_ecs_service.sandeep_strapi.name
}

output "rds_endpoint" {
  description = "RDS endpoint"
  value       = aws_db_instance.sandeep_strapi.address
}

output "log_group_name" {
  description = "CloudWatch log group"
  value       = aws_cloudwatch_log_group.sandeep_strapi.name
}

output "codedeploy_application_name" {
  description = "CodeDeploy application name"
  value       = aws_codedeploy_app.sandeep_strapi.name
}

output "codedeploy_deployment_group_name" {
  description = "CodeDeploy deployment group name"
  value       = aws_codedeploy_deployment_group.sandeep_strapi.deployment_group_name
}

output "cloudwatch_dashboard_name" {
  description = "CloudWatch dashboard name"
  value       = aws_cloudwatch_dashboard.sandeep_strapi.dashboard_name
}
