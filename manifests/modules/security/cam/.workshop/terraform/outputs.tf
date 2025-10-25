output "environment_variables" {
  description = "Environment variables to be added to the IDE shell"
  value = {
    READ_ONLY_IAM_ROLE  = aws_iam_role.eks_read_only.arn
    CARTS_TEAM_IAM_ROLE = aws_iam_role.eks_carts_team.arn
    DEVELOPERS_IAM_ROLE = aws_iam_role.eks_developers.arn
    ADMINS_IAM_ROLE     = aws_iam_role.eks_admins.arn
  }
}