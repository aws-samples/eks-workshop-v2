locals {
  base_bootstrap = file("${path.module}/scripts/bootstrap.sh")
}

resource "aws_ssm_document" "cloud9_bootstrap" {
  name            = "${var.environment_name}-cloud9-bootstrap"
  document_format = "YAML"
  document_type   = "Command"

  content = <<DOC
schemaVersion: '2.2'
description: Bootstrap Cloud9 Instance
mainSteps:
- action: aws:runShellScript
  name: Cloud9Bootstrap
  inputs:
    runCommand:
    - |
      set -e
      
      export CLOUD9_ENVIRONMENT_ID="${aws_cloud9_environment_ec2.c9_workspace.id}"
      
      echo "Running base bootstrap..."
      echo "${base64encode(local.base_bootstrap)}" | base64 -d | bash

      echo "Running extension bootstrap..."
      echo "${base64encode(var.bootstrap_script)}" | base64 -d | bash
DOC
}
