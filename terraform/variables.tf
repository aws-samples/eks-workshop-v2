variable "environment_suffix" {
  type        = string
  description = "Suffix for the workshop environment name"
  default     = ""
}

variable "cloud9_owner" {
  type        = string
  default     = ""
  description = "IAM role of the Cloud9 owner"
}

variable "repository_ref" {
  type        = string
  default     = "main"
  description = "The ref in the GitHub repository to clone"
}

variable "eks_role_arns" {
  type        = list(string)
  default     = []
  description = "Additional IAM roles that should be added to the AWS auth config map"
}
