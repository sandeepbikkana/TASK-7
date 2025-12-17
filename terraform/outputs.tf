output "alb_url" {
  value = "http://${aws_lb.strapi.dns_name}"
}

output "rds_endpoint" {
  value = aws_db_instance.strapi.address
}
output "log_group" {
  value = aws_cloudwatch_log_group.strapi.name
}
