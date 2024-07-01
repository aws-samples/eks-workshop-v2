#---------------------------------------
# Kuberay Operator
#---------------------------------------
enable_kuberay_operator = true
kuberay_operator_helm_config = {
  version = "1.1.0"
  # Enabling Volcano as Batch scheduler for KubeRay Operator
  values = [
    <<-EOT
      batchScheduler:
        enabled: true
    EOT
  ]
}