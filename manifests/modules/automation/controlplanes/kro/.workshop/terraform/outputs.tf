output "environment_variables" {
  description = "Environment variables to be added to the IDE shell"
  value = {
    DYNAMO_ACK_VERSION = var.dynamo_ack_version,
    KRO_VERSION        = var.kro_version,
    ACCOUNT_ID         = data.aws_caller_identity.current.account_id
  }
}