terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.67.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.22.0"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "2.10.1"
    }
  }

  required_version = ">= 1.3.7"
}