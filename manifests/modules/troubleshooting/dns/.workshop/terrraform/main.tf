
data "aws_region" "current" {}

locals {
  tags = {
    module = "troubleshooting"
  }
}

locals {
  account_id = data.aws_caller_identity.current.account_id
}

resource "null_resource" "break_app" {
  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = "bash ${path.module}/lab-setup.sh"
    when    = create
    # Optional: Set environment variables
    environment = {
      EKS_CLUSTER_NAME = var.addon_context.eks_cluster_id
      AWS_REGION       = data.aws_region.current.name
    }
  }
}