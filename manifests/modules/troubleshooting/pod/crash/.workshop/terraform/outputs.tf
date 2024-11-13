output "account_id" {
  value       = local.account_id
  description = "account id env variable"
}

output "environment_variables" {
  description = "Environment variables to be added to the IDE shell"
  value = merge({
    VPC_ID = data.aws_vpc.selected.id
    }, {
    for index, id in data.aws_subnets.public.ids : "PUBLIC_SUBNET_${index + 1}" => id
    }
  )
}