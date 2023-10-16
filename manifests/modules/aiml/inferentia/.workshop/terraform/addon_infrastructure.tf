resource "aws_s3_bucket" "inference" {
  bucket_prefix = "eksworkshop-inference"
  force_destroy = true

  tags = local.tags
}
