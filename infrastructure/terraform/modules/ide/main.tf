data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

provider "aws" {
  region = data.aws_region.current.id
  alias  = "default"
}