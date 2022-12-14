variable "id" {
  type        = string
  description = "Identifier for the cluster"
  default     = "cluster"
}

variable "cloud9_owner" {
  type    = string
  default = ""
}

variable "repository_ref" {
  type    = string
  default = "main"
}

variable "github_token" {
  type    = string
  default = ""
}
