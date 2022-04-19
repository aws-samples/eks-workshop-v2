variable "id" {
  type        = string
  description = "Identifier for the cluster"
  default     = "cluster"
}

variable "cloud9_user_arns" {
  type    = list(string)
  default = []
}