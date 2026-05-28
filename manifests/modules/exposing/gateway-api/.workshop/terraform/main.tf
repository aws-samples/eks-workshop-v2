resource "terraform_data" "gateway_api_crds" {
  provisioner "local-exec" {
    command = "kubectl apply --server-side=true -f https://github.com/kubernetes-sigs/gateway-api/releases/download/${var.gateway_api_version}/standard-install.yaml"
  }
}

resource "terraform_data" "lbc_gateway_crds" {
  provisioner "local-exec" {
    command = "kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/refs/heads/main/config/crd/gateway/gateway-crds.yaml"
  }

  depends_on = [terraform_data.gateway_api_crds]
}

module "eks_blueprints_addons" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "1.23.0"

  cluster_name      = var.addon_context.eks_cluster_id
  cluster_endpoint  = var.addon_context.aws_eks_cluster_endpoint
  cluster_version   = var.eks_cluster_version
  oidc_provider_arn = var.addon_context.eks_oidc_provider_arn

  enable_aws_load_balancer_controller = true
  aws_load_balancer_controller = {
    role_name   = "${var.addon_context.eks_cluster_id}-alb-controller"
    policy_name = "${var.addon_context.eks_cluster_id}-alb-controller"
  }

  create_kubernetes_resources = false

  observability_tag = null
}
