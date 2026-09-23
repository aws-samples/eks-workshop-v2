# tflint-ignore: terraform_unused_declarations
variable "eks_cluster_id" {
  description = "EKS cluster name, used as the per-environment suffix for the Identity Center user, group and secret"
  type        = string
}

# tflint-ignore: terraform_unused_declarations
variable "tags" {
  description = "Tags to apply to AWS resources"
  type        = any
}

# Set when something outside Terraform already created the instance for this
# environment, which is the case for a Workshop Studio event: the pre-provisioning
# build is not permitted to create one there, so the team stack creates it as a
# CloudFormation resource and passes the ARN in here.
#
# Empty everywhere else -- a self-service run or the GitHub Actions test flow -- where
# nothing has created an instance and this module is free to create one itself.
# tflint-ignore: terraform_unused_declarations
variable "idc_instance_arn" {
  description = "ARN of an IAM Identity Center instance already provisioned for this environment. Empty means this module manages the instance itself."
  type        = string
  default     = ""
}
