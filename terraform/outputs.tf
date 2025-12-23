################################
# GENERAL
################################
output "aws_region" {
  description = "AWS region where resources are deployed"
  value       = var.aws_region
}

################################
# LOAD BALANCER
################################
output "alb_name" {
  description = "Application Load Balancer name"
  value       = aws_lb.strapi.name
}

output "alb_arn" {
  description = "Application Load Balancer ARN"
  value       = aws_lb.strapi.arn
}

output "alb_dns_name" {
  description = "Public DNS name of the ALB (use this to access Strapi)"
  value       = aws_lb.strapi.dns_name
}

################################
# TARGET GROUPS
################################
output "blue_target_group_arn" {
  description = "Blue target group ARN"
  value       = aws_lb_target_group.blue.arn
}

output "green_target_group_arn" {
  description = "Green target group ARN"
  value       = aws_lb_target_group.green.arn
}

################################
# ECS
################################
output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = aws_ecs_cluster.strapi.name
}

output "ecs_service_name" {
  description = "ECS service name managed by CodeDeploy"
  value       = aws_ecs_service.strapi.name
}

output "ecs_task_definition_family" {
  description = "ECS task definition family (used by CI/CD when registering new revisions)"
  value       = aws_ecs_task_definition.baseline.family
}

################################
# CODEDEPLOY
################################
output "codedeploy_application_name" {
  description = "CodeDeploy ECS application name"
  value       = aws_codedeploy_app.ecs.name
}

output "codedeploy_deployment_group_name" {
  description = "CodeDeploy deployment group name"
  value       = aws_codedeploy_deployment_group.ecs.deployment_group_name
}

################################
# RDS
################################
output "rds_endpoint" {
  description = "PostgreSQL RDS endpoint"
  value       = aws_db_instance.strapi.endpoint
}

output "rds_port" {
  description = "PostgreSQL port"
  value       = aws_db_instance.strapi.port
}

output "rds_db_name" {
  description = "PostgreSQL database name"
  value       = aws_db_instance.strapi.db_name
}

################################
# SECURITY GROUPS
################################
output "alb_security_group_id" {
  description = "ALB security group ID"
  value       = aws_security_group.alb_sg.id
}

output "ecs_security_group_id" {
  description = "ECS service security group ID"
  value       = aws_security_group.ecs_sg.id
}

output "rds_security_group_id" {
  description = "RDS security group ID"
  value       = aws_security_group.rds_sg.id
}
