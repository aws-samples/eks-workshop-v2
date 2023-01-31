locals {
  ec2_name = "ack-ec2"
}

module "ec2" {
  source = "github.com/aws-ia/terraform-aws-eks-blueprints//modules/kubernetes-addons/helm-addon?ref=v4.12.2"

  helm_config = {
    name             = local.ec2_name
    chart            = "ec2-chart"
    repository       = "oci://public.ecr.aws/aws-controllers-k8s"
    version          = "v0.1.0"
    namespace        = local.ec2_name
    create_namespace = true
    description      = "ACK RDS Controller v2 Helm chart deployment configuration"
    values = [
      # shortens pod name from `ack-ec2-ec2-chart-xxxxxxxxxxxxx` to `ack-ec2-xxxxxxxxxxxxx`
      <<-EOT
        nameOverride: ack-ec2
      EOT
    ]
  }

  set_values = [
    {
      name  = "serviceAccount.name"
      value = local.ec2_name
    },
    {
      name  = "serviceAccount.create"
      value = false
    },
    {
      name  = "aws.region"
      value = data.aws_region.current.id
    }
  ]

  irsa_config = {
    create_kubernetes_namespace = true
    kubernetes_namespace        = local.ec2_name

    create_kubernetes_service_account = true
    kubernetes_service_account        = local.ec2_name

    irsa_iam_policies = [data.aws_iam_policy.ec2.arn]
  }

  addon_context = local.addon_context
}

data "aws_iam_policy" "ec2" {
  name = "AmazonEC2FullAccess"
}
