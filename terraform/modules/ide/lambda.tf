module "cloud9_bootstrap_lambda" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "3.1.0"

  publish = true

  function_name = "${var.environment_name}-cloud9-bootstrap"
  handler       = "bootstrap.lambda_handler"
  runtime       = "python3.9"
  timeout       = 900

  attach_policies    = true
  policies           = [aws_iam_policy.cloud9_bootstrap_lambda_policy.id]
  number_of_policies = 1

  source_path = [
    "${path.module}/functions/src/bootstrap.py",
  ]
}

resource "aws_iam_policy" "cloud9_bootstrap_lambda_policy" {
  name = "${var.environment_name}-cloud9-bootstrap"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeIamInstanceProfileAssociations",
          "ec2:DescribeVolumes",
          "ec2:AssociateIamInstanceProfile",
          "ec2:ModifyVolume",
          "ec2:ReplaceIamInstanceProfileAssociation",
          "iam:ListInstanceProfiles",
          "iam:PassRole",
          "ssm:DescribeInstanceInformation",
          "ssm:SendCommand",
          "ssm:GetCommandInvocation"
        ],
        Resource = "*"
      }
    ]
  })
}
