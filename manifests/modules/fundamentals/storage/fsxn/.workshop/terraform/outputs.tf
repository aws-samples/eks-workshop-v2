output "environment_variables" {
  description = "Environment variables to be added to the IDE shell"
  value = {
    FSXN_ID             = aws_fsx_ontap_file_system.fsxnassets.id
    FSXN_ADMIN_PASSWORD = random_string.fsx_password.result
    FSXN_IP             = tolist(aws_fsx_ontap_file_system.fsxnassets.endpoints[0].management[0].ip_addresses)[0]
  }
}