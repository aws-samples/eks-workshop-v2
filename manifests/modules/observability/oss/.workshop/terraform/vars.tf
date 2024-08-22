# tflint-ignore: terraform_unused_declarations
variable "eks_cluster_id" {
  description = "EKS cluster name"
  type        = string
}

# tflint-ignore: terraform_unused_declarations
variable "eks_cluster_version" {
  description = "EKS cluster version"
  type        = string
}

# tflint-ignore: terraform_unused_declarations
variable "cluster_security_group_id" {
  description = "EKS cluster security group ID"
  type        = any
}

# tflint-ignore: terraform_unused_declarations
variable "addon_context" {
  description = "Addon context that can be passed directly to blueprints addon modules"
  type        = any
}

# tflint-ignore: terraform_unused_declarations
variable "tags" {
  description = "Tags to apply to AWS resources"
  type        = any
}

# tflint-ignore: terraform_unused_declarations
variable "resources_precreated" {
  description = "Have expensive resources been created already"
  type        = bool
}

variable "opentelemetry_operator_chart_version" {
  description = "The chart version of opentelemetry-operator to use"
  type        = string
  # renovate-helm: depName=opentelemetry-operator registryUrl=https://open-telemetry.github.io/opentelemetry-helm-charts
  default = "0.68.0"
}

variable "loki_chart_version" {
  description = "The chart version of loki to use"
  type        = string
  # renovate-helm: depName=loki registryUrl=https://grafana.github.io/helm-charts
  default = "6.10.0"
}

variable "tempo_chart_version" {
  description = "The chart version of tempo to use"
  type        = string
  # renovate-helm: depName=tempo registryUrl=https://grafana.github.io/helm-charts
  default = "1.10.3"
}

variable "grafana_operator_chart_version" {
  description = "The chart version of grafana-operator to use"
  type        = string
  # renovate-helm: depName=grafana-operator registryUrl=oci://ghcr.io/grafana/helm-charts
  default = "v5.12.0"
}

variable "kubecost_chart_version" {
  description = "The chart version of kubecost to use"
  type        = string
  # renovate-helm: depName=cost-analyzer registryUrl=https://kubecost.github.io/cost-analyzer
  default = "1.108.1"
}
