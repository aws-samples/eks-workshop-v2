output "cloud9_url" {
  value       = "https://${data.aws_region.current.id}.console.aws.amazon.com/cloud9/ide/${aws_cloud9_environment_ec2.c9_workspace.id}"
  description = "URL to the Cloud9 IDE instance"
}

output "cloud9_environment_id" {
  value       = aws_cloud9_environment_ec2.c9_workspace.id
  description = "Cloud9 environment ID"
}
