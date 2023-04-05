module "argocd" {
  source        = "github.com/aws-ia/terraform-aws-eks-blueprints?ref=v4.25.0//modules/kubernetes-addons/argocd"
  addon_context = local.addon_context

  helm_config = {
    name             = "argocd"
    chart            = "argo-cd"
    repository       = "https://argoproj.github.io/argo-helm"
    version          = "5.25.0"
    namespace        = "argocd"
    timeout          = 1200
    create_namespace = true

    set = [{
      name  = "server.replicas"
      value = "1"
    },{
      name  = "controller.replicas"
      value = "1"
    },{
      name  = "repoServer.replicas"
      value = "1"
    },{
      name  = "applicationSet.replicaCount"
      value = "1"
    },{
      name  = "redis-ha.enabled"
      value = "false"
    },{
      name  = "server.service.type"
      value = "LoadBalancer"
    }]
  }
}