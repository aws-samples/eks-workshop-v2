terraform {
  required_providers {
    #    kubectl = {
    #      source  = "gavinbunney/kubectl"
    #      version = ">= 1.14"
    #    }
  }
}

provider "aws" {
  region = "us-east-1"
  alias  = "virginia"
}

data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
}


resource "null_resource" "kustomize_app" {
  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = "kubectl apply -f ~/environment/eks-workshop/modules/troubleshooting/pod/image/"
    when    = create
  }
}

