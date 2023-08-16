variable "environment_name" {
  type    = string
  default = "eks-workshop"
}

variable "cluster_version" {
  description = "EKS cluster version."
  type        = string
  default     = "1.25"
}

variable "ami_release_version" {
  description = "Default EKS AMI release version for node groups"
  type        = string
  default     = " 1.25.6-20230304"
}

variable "vpc_cidr" {
  description = "Defines the CIDR block used on Amazon VPC created for Amazon EKS."
  type        = string
  default     = "10.42.0.0/16"
}

variable "public_subnet_tags" {
  description = "Tags to be added specifically on public facing subnets."
  type        = map(string)
  default     = {
    "kubernetes.io/role/elb" = "1"
  }
}

variable "private_subnet_tags" {
  description = "Tags to be added specifically on private subnets."
  type        = map(string)
  default     = {}
}