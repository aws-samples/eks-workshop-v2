module "eks-blueprints-kubernetes-addons" {
  source = "github.com/aws-ia/terraform-aws-eks-blueprints?ref=v4.0.1//modules/kubernetes-addons"

  eks_cluster_id = module.aws-eks-accelerator-for-terraform.eks_cluster_id

  enable_aws_load_balancer_controller = true
  aws_load_balancer_controller_helm_config = {
    version    = var.aws_load_balancer_controller_version
  }
}