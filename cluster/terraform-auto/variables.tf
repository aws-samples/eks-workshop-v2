variable "auto_cluster_name" {
  description = "Name of the EKS Auto Mode cluster"
  type        = string
  default     = "eks-workshop-auto"
}

variable "cluster_version" {
  description = "EKS cluster version"
  type        = string
  default     = "1.33"
}
