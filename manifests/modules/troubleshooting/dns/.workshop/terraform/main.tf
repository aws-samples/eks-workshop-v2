
data "aws_region" "current" {}

locals {
  tags = {
    module = "troubleshooting"
  }
}

locals {
  account_id = data.aws_caller_identity.current.account_id
}