output "environment" {
  description = "Evaluated by the IDE shell"

  # At least one lab exports a credential through here: the Argo CD lab passes the
  # IAM Identity Center password it read from Secrets Manager, and the AWS provider
  # marks that value sensitive. Terraform refuses to render a root output carrying a
  # sensitive value unless the intent is declared, so declare it.
  #
  # This costs nothing downstream. reset-environment reads this with
  # `terraform output -json`, which still returns the value, and marking it keeps the
  # credential out of the apply output participants see on screen.
  sensitive = true

  value = <<EOF
%{for k, v in local.environment_variables}
export ${k}='${v}'
%{endfor}
EOF
}
