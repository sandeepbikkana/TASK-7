variable "aws_region" {
  default = "ap-south-1"
}

variable "ecr_repo" {
  description = "Full ECR repository URI"
}

variable "image_tag" {
  description = "Docker image tag"
}

variable "db_name" {
  default = "strapi"
}

variable "db_username" {
  type = string
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "app_keys" {
  type      = string
  sensitive = true
}

variable "admin_jwt_secret" {
  type      = string
  sensitive = true
}

variable "jwt_secret" {
  type      = string
  sensitive = true
}

variable "api_token_salt" {
  type      = string
  sensitive = true
}
