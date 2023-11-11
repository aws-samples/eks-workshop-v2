/**
 * Setup Lambda function to export EKS control plane logs from 
 * CloudWatch to OpenSearch. This Terraform sets up the Lambda function, 
 * the execution role and the resource policy to enable CloudWatch to 
 * invoke the Lambda function. 
 *
 * Lab participants will (manually) execute the steps to enable control plane logging, 
 * which creates the appropriate log group, enable the cloudwatch subscription
 * filter and setup the necessary OpenSearch domain permissions.   
 * 
 * This split provisioning approach is used because the CloudWatch subscription 
 * filter can only be enabled AFTER the log group is created, and the log group for 
 * control plane logs is created only enabled within the lab module as part of the 
 * lab instructions.  
 */

locals {
  cw_logs_arn_prefix        = arn:aws:logs:${local.addon_context.aws_region_name}:${local.addon_context.aws_caller_identity_account_id}
  lambda_function_name      = "${local.addon_context.eks_cluster_id}-Control-Plane-Logs-To-OpenSearch"
}



 // Random suffix for IAM roles, policies
resource "random_string" "suffix" {
  length = 6
  upper = false
  special = false
}

// Lambda execution role for CloudWatch subscription
resource "aws_iam_role" "lambda_execution_role" {
  name               = "cloudwatch_subscription_lambda_role_${random_string.suffix.result}"

  // Trust relationship 
  assume_role_policy = jsonencode({
      "Version": "2012-10-17",
      "Statement": [
        {
          "Action": "sts:AssumeRole",
          "Principal": {
            "Service": "lambda.amazonaws.com"
          },
          "Effect": "Allow",
          "Sid": ""
        }
      ]
  })

  // Attach inline policy
  inline_policy {
    name = "policy-${random_string.suffix.result}"
    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Action   = ["es:*"]
            Effect   = "Allow"
            Resource = "*"  
          },
          {
            Action   = ["ssm:GetParameter", "kms:Decrypt"]
            Effect   = "Allow"
            Resource = "*"
          },
          {
            Action   = ["logs:CreateLogGroup"]
            Effect   = "Allow"
            Resource = local.cw_logs_arn_prefix
          },
          {
            Action   = ["logs:CreateLogStream", "logs:PutLogEvents"]
            Effect   = "Allow"
            Resource = "${local.cw_logs_arn_prefix}:log-group:/aws/lambda/${local.lambda_function_name}:*"
          }          
        ]
      })
  }
}

// Create ZIP file with Lambda code
data "archive_file" "lambda" {
  type        = "zip"
  source_file = "logs-to-opensearch.js"
  output_path = "lambda_function_payload.zip"
}

// Create Lambda function to export logs to OpenSearch
resource "aws_lambda_function" "eks_control_plane_logs_to_opensearch" {
  filename      = "lambda_function_payload.zip"
  function_name = local.lambda_function_name
  role          = aws_iam_role.lambda_execution_role.arn
  handler       = "logs-to-opensearch.handler"

  source_code_hash = data.archive_file.lambda.output_base64sha256

  runtime = "nodejs18.x"

  environment {
    variables = {
      eks_cluster_id    = ${local.addon_context.eks_cluster_id}
      opensearch_index  = 'eks-control-plane-logs'
    }
  }
}

// Enable CloudWatch Logs to invoke Lambda function that exports to OpenSearch. 
// This sets up resource-based policy for Lambda.  Note that source ARN for the EKS 
// control plane log group has not yet been created at the time of terraform apply.  
// The logs group is created when the workshop participant (manually) runs the 
// step to enable EKS Control Plane Logs.  
resource "aws_lambda_permission" "allow_cloudwatch_to_invoke_lambda" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.eks_control_plane_logs_to_opensearch.function_name
  principal     = "logs.${local.addon_context.aws_region_name}.amazonaws.com"
  source_arn    = "${local.cw_logs_arn_prefix}:log-group:/aws/eks/${local.addon_context.eks_cluster_id}/cluster:*"
}
