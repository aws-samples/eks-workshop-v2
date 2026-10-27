terraform {
  required_providers {
    helm = {
      source                = "hashicorp/helm"
      version               = "2.17.0"
      configuration_aliases = [helm.auto_mode]
    }
    kubernetes = {
      source                = "hashicorp/kubernetes"
      version               = "2.38.0"
      configuration_aliases = [kubernetes.auto_mode]
    }
  }
}
