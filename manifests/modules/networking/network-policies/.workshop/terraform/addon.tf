module "eks_blueprints_addons" {
  source = "aws-ia/eks-blueprints-addons/aws"
  version = "~> 1.0"

  enable_aws_load_balancer_controller = true

  cluster_name      = local.addon_context.eks_cluster_id
  cluster_endpoint  = local.addon_context.aws_eks_cluster_endpoint
  cluster_version   = local.eks_cluster_version
  oidc_provider_arn = local.addon_context.eks_oidc_provider_arn
}

resource "aws_ssm_document" "mount_networkpolicy_fs" {
  count = startswith(local.eks_cluster_version,"1.25") || startswith(local.eks_cluster_version,"1.26") ? 1 : 0
  name            = "mount_networkpolicy_fs_doc"
  document_format = "YAML"
  document_type   = "Command"

  content = <<DOC
schemaVersion: '1.2'
description: Mount BPF File system
parameters: {}
runtimeConfig:
  'aws:runShellScript':
    properties:
      - id: '0.aws:runShellScript'
        runCommand:
          - sudo mount -t bpf bpffs /sys/fs/bpf
DOC
}

resource "aws_ssm_association" "mount_networkpolicy_fs" {
  count = startswith(local.eks_cluster_version,"1.25") || startswith(local.eks_cluster_version,"1.26") ? 1 : 0
  name = "${aws_ssm_document.mount_networkpolicy_fs.*.name[count.index]}"

  targets {
    key    = "tag:created-by"
    values = ["eks-workshop-v2"]
  }
}
