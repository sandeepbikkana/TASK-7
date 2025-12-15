output "alb_url" {
  value = aws_lb.strapi.dns_name
}
