terraform {
  backend "s3" {
    key     = "eks-workshop/terraform.tfstate"
    encrypt = true
  }
}