variable "aws_region" {
  default = "ap-south-1"
}

variable "ecr_repo" {}
variable "image_tag" {}

variable "ecs_execution_role_arn" {
  description = "Pre-created ECS task execution role"
}
