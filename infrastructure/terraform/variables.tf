variable "cluster_id" {
  type        = string
  description = "Identifier for the cluster"
  default     = "cluster"
}

variable "repository_ref" {
  type    = string
  default = "main"
}

variable "cloud9_owner" {
  type    = string
  default = ""
}

variable "eks_additional_role" {
  type    = string
  default = ""
}
