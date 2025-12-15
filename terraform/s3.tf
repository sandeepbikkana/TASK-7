terraform {
  backend "s3" {
    bucket         = "terra-tf-buck-12"
    key            = "strapi/ecs/terraform.tfstate"
    region         = "ap-south-1"
    encrypt        = true
    # dynamodb_table = "terraform-locks"
  }
}
