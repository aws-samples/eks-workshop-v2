output "environment_variables" {
  description = "Environment variables to be added to the IDE shell"
  value = {
    VPC_ID = data.aws_vpc.this.id
  }
}