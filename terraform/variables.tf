variable "id" {
  type        = string
  description = "Identifier for the cluster"
  default     = "cluster"
}

variable "repository_archive_location" {
  type        = string
  description = "Location of the repository archive"
  default     = ""
}

variable "cloud9_user_arns" {
  type    = list(string)
  default = [""]
}