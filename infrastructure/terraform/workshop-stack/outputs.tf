output "bucket_arn" {
  description = "Amazon S3 Bucket ARN"
  value       = resource.aws_s3_bucket.my_bucket.arn
}
