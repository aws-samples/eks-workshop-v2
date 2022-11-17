variable "instance_type" {
  type        = string
  description = "Instance type for C9"
  default     = "t3.medium"
}

variable "subnet_id" {
  type        = string
  description = "Target subnet for the C9 instance"
  default     = ""
}

variable "environment_name" {
  type    = string
  default = "test"
}

variable "disk_size" {
  type    = number
  default = 60
}

variable "bootstrap_script" {
  type    = string
  default = "echo 'No extension bootstrap'"
}

variable "additional_cloud9_policies" {
  type    = list(any)
  default = []
}

variable "additional_cloud9_policy_arns" {
  type    = list(string)
  default = []
}

variable "cloud9_user_arns" {
  type    = list(string)
  default = []
}

variable "tags" {
  type    = map(string)
  default = {}
}