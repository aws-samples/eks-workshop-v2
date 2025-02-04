output "secret_arn" {
  description = "fsxn password secret arn"
  value = aws_secretsmanager_secret.fsxn_password_secret.arn
}

output "fsxn_fs_id" {
  description = "fsxn file system id"
  value = aws_fsx_ontap_file_system.fsxn_filesystem.id
}

output "fsxn_svm_name" {
  description = "fsxn svm name"
  value = aws_fsx_ontap_storage_virtual_machine.fsxn_svm.name
}