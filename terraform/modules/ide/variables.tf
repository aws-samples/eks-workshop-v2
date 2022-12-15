variable "instance_type" {
  type        = string
  description = "EC2 instance type for the Cloud9 instance"
  default     = "t3.medium"
}

variable "subnet_id" {
  type        = string
  description = "Target subnet for the Cloud9 instance"
}

variable "environment_name" {
  type        = string
  description = "Name of the environment"
}

variable "disk_size" {
  type        = number
  description = "Disk size of the Cloud9 instance"
  default     = 60
}

variable "bootstrap_script" {
  type        = string
  description = "Bash script run to bootstrap the Cloud9 instance after its running"
  default     = "echo 'No extension bootstrap'"
}

variable "additional_cloud9_policies" {
  type        = list(any)
  description = "Additional IAM policy objects to be attached to the Cloud9 role"
  default     = []
}

variable "additional_cloud9_policy_arns" {
  type        = list(string)
  description = "ARNs of additional IAM policies to be attached to the Cloud9 role"
  default     = []
}

variable "cloud9_owner" {
  type        = string
  description = "ARN of the Cloud9 owner user"
  default     = ""
}

variable "tags" {
  type        = map(string)
  description = "AWS tags that will be applied to all resources"
  default     = {}
}
