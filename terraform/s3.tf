terraform {
  backend "s3" {
    bucket  = "sandeep-tfstate-buck"
    key     = "strapi/terraform.tfstate"  # inside the bucket
    region  = "ap-south-1"
    encrypt = true
  }
}
