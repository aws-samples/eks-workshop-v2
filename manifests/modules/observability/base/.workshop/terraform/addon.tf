resource "kubernetes_cluster_role" "eks-console-dashboard-full-access-clusterrole" {
  metadata {
    name = "eks-console-dashboard-full-access-clusterrole"
  }

  rule {
    api_groups = [""]
    resources  = ["nodes", "namespaces", "pods", "configmaps", "endpoints", "events", "limitranges", "persistentvolumeclaims", "podtemplates", "replicationcontrollers", "resourcequotas", "secrets", "serviceaccounts", "services"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["apps"]
    resources  = ["deployments", "daemonsets", "statefulsets", "replicasets"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["batch"]
    resources  = ["jobs","cronjobs"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["coordination.k8s.io"]
    resources  = ["leases"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["discovery.k8s.io"]
    resources  = ["endpointslices"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["events.k8s.io"]
    resources  = ["events"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["extensions"]
    resources  = ["daemonsets", "deployments", "ingresses", "networkpolicies", "replicasets"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["networking.k8s.io"]
    resources  = ["ingresses", "networkpolicies"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["policy"]
    resources  = ["poddisruptionbudgets"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["rbac.authorization.k8s.io"]
    resources  = ["rolebindings", "roles"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["storage.k8s.io"]
    resources  = ["csistoragecapacities"]
    verbs      = ["get", "list", "watch"]
  }
}


resource "kubernetes_cluster_role_binding" "eks-console-dashboard-full-access-binding" {
  metadata {
    name = "eks-console-dashboard-full-access-binding"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "eks-console-dashboard-full-access-clusterrole"
  }

  subject {
    kind      = "Group"
    name      = "eks-console-dashboard-full-access-group"
    api_group = "rbac.authorization.k8s.io"
  }

}

data "external" "env" {
  program = ["${path.module}/env.sh"]
}

resource "terraform_data" "console-iam-rbac-mapping" {

  provisioner "local-exec" {
    command = <<-EOT
      echo "Mapping RBAC Permissions"      
      user_instance=(${data.external.env.result["C9_USER"]})
      if [[ ! -z "$${user_instance}" ]]; then
        echo "Mapping user $${user_instance} to RBAC "
        eksctl create iamidentitymapping --cluster ${local.addon_context.eks_cluster_id} --region ${data.aws_region.current.id} \
        --arn arn:aws:iam::${local.addon_context.aws_caller_identity_account_id}:user/$${user_instance} --username console-iam-user --group eks-console-dashboard-full-access-group \
        --no-duplicate-arns -d > /dev/null  2>&1

        eksctl create iamidentitymapping --cluster ${local.addon_context.eks_cluster_id} --region ${data.aws_region.current.id} \
        --arn arn:aws:iam::${local.addon_context.aws_caller_identity_account_id}:role/$${user_instance} --username console-iam-role --group eks-console-dashboard-full-access-group \
        --no-duplicate-arns -d > /dev/null  2>&1
      fi

    EOT
 }
}
