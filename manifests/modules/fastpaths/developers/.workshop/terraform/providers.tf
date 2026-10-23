terraform {
  required_providers {
    helm = {
      source                = "hashicorp/helm"
      version               = "3.3.0"
      configuration_aliases = [helm.auto_mode]
    }
    kubernetes = {
      source                = "hashicorp/kubernetes"
      version               = "3.2.1"
      configuration_aliases = [kubernetes.auto_mode]
    }
  }
}
