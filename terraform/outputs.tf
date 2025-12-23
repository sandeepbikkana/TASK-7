################################
# GENERAL
################################

output "aws_region" {
  description = "AWS region"
  value       = var.aws_region
}

output "vpc_id" {
  description = "Default VPC ID"
  value       = data.aws_vpc.default.id
}

################################
# ECS
################################

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = aws_ecs_cluster.sandeep_strapi.name
}

output "ecs_service_name" {
  description = "ECS service name"
  value       = aws_ecs_service.sandeep_strapi.name
}

output "ecs_task_family" {
  description = "ECS task definition family"
  value       = aws_ecs_task_definition.sandeep_strapi.family
}

################################
# LOAD BALANCER
################################

output "alb_name" {
  description = "Application Load Balancer name"
  value       = aws_lb.sandeep_strapi.name
}

output "alb_dns_name" {
  description = "Application Load Balancer DNS name"
  value       = aws_lb.sandeep_strapi.dns_name
}

output "alb_listener_arn" {
  description = "ALB HTTP listener ARN"
  value       = aws_lb_listener.sandeep_http.arn
}

output "blue_target_group_arn" {
  description = "Blue target group ARN"
  value       = aws_lb_target_group.sandeep_blue.arn
}

output "green_target_group_arn" {
  description = "Green target group ARN"
  value       = aws_lb_target_group.sandeep_green.arn
}

################################
# CODEDEPLOY
################################

output "codedeploy_application_name" {
  description = "CodeDeploy application name"
  value       = aws_codedeploy_app.sandeep_strapi.name
}

output "codedeploy_deployment_group_name" {
  description = "CodeDeploy deployment group name"
  value       = aws_codedeploy_deployment_group.sandeep_strapi.deployment_group_name
}

################################
# RDS
################################

output "rds_endpoint" {
  description = "PostgreSQL RDS endpoint"
  value       = aws_db_instance.sandeep_strapi.endpoint
}

output "rds_db_name" {
  description = "PostgreSQL database name"
  value       = aws_db_instance.sandeep_strapi.db_name
}

################################
# CLOUDWATCH
################################

output "cloudwatch_log_group_name" {
  description = "ECS CloudWatch log group name"
  value       = aws_cloudwatch_log_group.sandeep_strapi.name
}

output "cloudwatch_dashboard_name" {
  description = "CloudWatch dashboard name"
  value       = aws_cloudwatch_dashboard.sandeep_strapi.dashboard_name
}
