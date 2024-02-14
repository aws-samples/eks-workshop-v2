variable "cluster_name" {
  type    = string
  default = "eks-workshop"
}

variable "cluster_version" {
  description = "EKS cluster version."
  type        = string
  default     = "1.29"
}

variable "ami_release_version" {
  description = "Default EKS AMI release version for node groups"
  type        = string
  default     = "1.29.0-20240129"
}

variable "vpc_cidr" {
  description = "Defines the CIDR block used on Amazon VPC created for Amazon EKS."
  type        = string
  default     = "10.42.0.0/16"
}