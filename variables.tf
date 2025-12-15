# variable "aws_region" {
#   default = "ap-south-1"
# }

# variable "ecr_repo" {
#   default = "730335385079.dkr.ecr.ap-south-1.amazonaws.com/task-7"
# }

# variable "image_tag" {default ="0500510f" }

# variable "ecs_execution_role_arn" {
#   description = "Existing ECS execution role"
# }

# # --- Strapi Secrets ---
# variable "app_keys" {default = "ba93e7f9a88b4e648aa9e2d1d8b3c7ff,8c44e9a0dc4f452da9b2b6e8a09bfc3d,fc8c319a89d64c95b8e6f4420f2e7da4,b7b3a4e26bb94a09a5e6288d2f2e0d19"}
# variable "admin_jwt_secret" {default ="8fa2a7bcb6a6400a85e3a5b87d23b8c9" }
# variable "api_token_salt" {default ="OTM4YzQ3ZjZlM2EzN2Q2Ng=="}
# variable "jwt_secret" {default ="JHNKA9NVfw0Oi2VsIA06Tw==" }

# --- Database ---
# variable "db_host" {}
# variable "db_name" {}
# variable "db_username" {}
# variable "db_password" {}


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
