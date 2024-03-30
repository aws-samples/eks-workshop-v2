output "environment" {
  description = "Evaluated by the IDE shell"
  value       = <<EOF
%{for k, v in local.environment_variables}
export ${k}='${v}'
%{endfor}
EOF
}
