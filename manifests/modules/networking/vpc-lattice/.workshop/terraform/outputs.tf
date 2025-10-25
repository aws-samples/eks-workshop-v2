output "environment_variables" {
  description = "Environment variables to be added to the IDE shell"
  value = {
    VPC_ID                     = data.aws_vpc.this.id
    LATTICE_IAM_ROLE           = module.iam_assumable_role_lattice.iam_role_arn
    LATTICE_CONTROLLER_VERSION = var.lattice_controller_version
  }
}