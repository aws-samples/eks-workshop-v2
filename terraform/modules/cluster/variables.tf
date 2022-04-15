variable "cluster_version" {
  type        = string
  description = "Kubernetes Version"
  default     = "1.22"
}

variable "id" {
  type        = string
  description = "Identifier for the cluster"
}