output "environment_variables" {
  description = "Environment variables to be added to the IDE shell"
  value = {
    CARTS_DYNAMODB_TABLENAME = aws_dynamodb_table.carts.name
    CARTS_IAM_ROLE           = module.iam_assumable_role_carts.iam_role_arn
    KIRO_START_URL           = aws_cloudformation_stack.kiro_idc.outputs["KiroStartURL"]
    KIRO_USER                = aws_cloudformation_stack.kiro_idc.outputs["KiroUser"]
    KIRO_PASSWORD            = aws_cloudformation_stack.kiro_idc.outputs["KiroPassword"]
    KIRO_REGION              = aws_cloudformation_stack.kiro_idc.outputs["KiroRegion"]
  }
}
