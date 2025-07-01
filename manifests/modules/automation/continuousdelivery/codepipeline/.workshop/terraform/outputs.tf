output "environment_variables" {
  description = "Environment variables to be added to the IDE shell"
  value = {
    IMAGE_URI_UI     = aws_ecr_repository.ecr_ui.repository_url
    S3_SOURCE_BUCKET = aws_s3_bucket.source_bucket.id
  }
}
