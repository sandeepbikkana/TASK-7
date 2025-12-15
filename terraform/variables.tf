variable "aws_region" { default = "ap-south-1" }

variable "instance_type" { default = "t3.micro" }

variable "docker_repo" { default = "sandeep-strapi" }

variable "image_tag" { type = string }

# variable "db_name" { default = "strapi" }
variable "db_username" { default = "postgres" }
variable "db_password" { default = "StrapiDB123!" }

variable "key_name" { default = "sandeep-test" }
variable "project" { default = "sandeep" }

variable "ACCOUNT_ID" { default = "301782007642" }
variable "aws_access_key_id" {
  type = string
  sensitive = true
}

variable "aws_secret_access_key" {
  type = string
  sensitive = true
}
