data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

locals {
  capability_role_name = "${var.addon_context.eks_cluster_id}-argocd-capability"
}

resource "aws_iam_role" "argocd_capability" {
  name = local.capability_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "capabilities.eks.amazonaws.com" }
      Action    = ["sts:AssumeRole", "sts:TagSession"]
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "argocd_capability_sso" {
  name = "ArgocdCapabilitySsoPolicy"
  role = aws_iam_role.argocd_capability.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["sts:GetCallerIdentity"]
      Resource = ["*"]
    }]
  })
}

# EKS validates the trust policy before IAM propagates globally (~15s).
resource "time_sleep" "iam_propagation" {
  depends_on      = [aws_iam_role_policy.argocd_capability_sso]
  create_duration = "30s"
}

resource "null_resource" "idc_instance" {
  triggers = {
    region = data.aws_region.current.id
  }

  provisioner "local-exec" {
    command = <<-EOF
      set -e
      REGION="${data.aws_region.current.id}"

      IDC_JSON=$(aws sso-admin list-instances --region $REGION --output json)
      COUNT=$(echo "$IDC_JSON" | jq '.Instances | length')

      if [ "$COUNT" = "0" ]; then
        IDC_STATUS="NOTFOUND"
        IDC_ARN=""
      else
        IDC_ARN=$(echo "$IDC_JSON" | jq -r '.Instances[0].InstanceArn')
        IDC_STATUS=$(echo "$IDC_JSON" | jq -r '.Instances[0].Status')
      fi
      echo "IDC status: $IDC_STATUS"

      if [ "$IDC_STATUS" = "ACTIVE" ]; then
        echo "IDC instance already ACTIVE: $IDC_ARN"
        exit 0
      fi

      if [ "$IDC_STATUS" = "CREATE_FAILED" ]; then
        echo "Removing CREATE_FAILED instance..."
        aws sso-admin delete-instance --instance-arn "$IDC_ARN" --region $REGION
        for i in $(seq 1 60); do
          COUNT=$(aws sso-admin list-instances --region $REGION --output json | jq '.Instances | length')
          [ "$COUNT" = "0" ] && break
          sleep 5
        done
      fi

      echo "Creating IDC instance..."
      IDC_ARN=$(aws sso-admin create-instance --name eks-workshop \
        --region $REGION --output json | jq -r '.InstanceArn')
      echo "IDC ARN: $IDC_ARN"

      for i in $(seq 1 60); do
        STATUS=$(aws sso-admin describe-instance --instance-arn "$IDC_ARN" \
          --region $REGION --output json | jq -r '.Status // "UNKNOWN"')
        echo "  [$i] IDC status: $STATUS"
        [ "$STATUS" = "ACTIVE" ] && exit 0
        [ "$STATUS" = "CREATE_FAILED" ] && echo "IDC CREATE_FAILED" && exit 1
        sleep 5
      done
      echo "Timeout waiting for IDC ACTIVE"
      exit 1
    EOF
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOF
      REGION="${self.triggers.region}"
      IDC_ARN=$(aws sso-admin list-instances --region $REGION --output json \
        | jq -r '.Instances[] | select(.Name=="eks-workshop") | .InstanceArn // empty' | head -1)
      if [ -n "$IDC_ARN" ]; then
        echo "Deleting IDC instance $IDC_ARN..."
        aws sso-admin delete-instance --instance-arn "$IDC_ARN" --region $REGION 2>/dev/null || true
      fi
    EOF
  }
}

data "aws_ssoadmin_instances" "main" {
  depends_on = [null_resource.idc_instance]
}

resource "aws_identitystore_user" "argocd_admin" {
  identity_store_id = tolist(data.aws_ssoadmin_instances.main.identity_store_ids)[0]

  user_name    = "argocd-admin@eksworkshop.com"
  display_name = "ArgoCD Workshop Admin"

  name {
    given_name  = "ArgoCD"
    family_name = "Admin"
  }

  emails {
    value   = "argocd-admin@eksworkshop.com"
    primary = true
  }
}

resource "null_resource" "cleanup_stale_access_entry" {
  depends_on = [time_sleep.iam_propagation]

  triggers = {
    role_arn     = aws_iam_role.argocd_capability.arn
    cluster_name = var.addon_context.eks_cluster_id
    region       = data.aws_region.current.id
  }

  provisioner "local-exec" {
    command = <<-EOF
      aws eks delete-access-entry \
        --region ${self.triggers.region} \
        --cluster-name ${self.triggers.cluster_name} \
        --principal-arn ${self.triggers.role_arn} 2>/dev/null || true
    EOF
  }
}

resource "aws_eks_capability" "argocd" {
  depends_on = [
    null_resource.cleanup_stale_access_entry,
    aws_identitystore_user.argocd_admin,
  ]

  cluster_name              = var.addon_context.eks_cluster_id
  capability_name           = "argocd"
  type                      = "ARGOCD"
  role_arn                  = aws_iam_role.argocd_capability.arn
  delete_propagation_policy = "RETAIN"

  configuration {
    argo_cd {
      aws_idc {
        idc_instance_arn = tolist(data.aws_ssoadmin_instances.main.arns)[0]
        idc_region       = data.aws_region.current.id
      }

      rbac_role_mapping {
        role = "ADMIN"
        identity {
          id   = aws_identitystore_user.argocd_admin.user_id
          type = "SSO_USER"
        }
      }
    }
  }
}

resource "null_resource" "argocd_capability_access_entry" {
  depends_on = [aws_eks_capability.argocd]

  triggers = {
    role_arn     = aws_iam_role.argocd_capability.arn
    cluster_name = var.addon_context.eks_cluster_id
    region       = data.aws_region.current.id
  }

  provisioner "local-exec" {
    command = <<-EOF
      aws eks create-access-entry \
        --region ${self.triggers.region} \
        --cluster-name ${self.triggers.cluster_name} \
        --principal-arn ${self.triggers.role_arn} 2>/dev/null || true
      aws eks associate-access-policy \
        --region ${self.triggers.region} \
        --cluster-name ${self.triggers.cluster_name} \
        --principal-arn ${self.triggers.role_arn} \
        --policy-arn arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy \
        --access-scope type=cluster
    EOF
  }
}

resource "null_resource" "argocd_manager_rbac" {
  depends_on = [aws_eks_capability.argocd]

  triggers = {
    cluster_name = var.addon_context.eks_cluster_id
  }

  provisioner "local-exec" {
    command = <<-EOF
      kubectl create clusterrolebinding argocd-manager-cluster-admin \
        --clusterrole=cluster-admin \
        --serviceaccount=kube-system:argocd-manager 2>/dev/null || true
    EOF
  }

  provisioner "local-exec" {
    when    = destroy
    command = "kubectl delete clusterrolebinding argocd-manager-cluster-admin 2>/dev/null || true"
  }
}

resource "aws_codecommit_repository" "argocd" {
  repository_name = "${var.addon_context.eks_cluster_id}-argocd"
  description     = "CodeCommit repository for ArgoCD"
}

resource "aws_iam_user" "gitops" {
  name = "${var.addon_context.eks_cluster_id}-gitops"
  path = "/"
}

resource "tls_private_key" "gitops" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_iam_user_ssh_key" "gitops" {
  username   = aws_iam_user.gitops.name
  encoding   = "SSH"
  public_key = tls_private_key.gitops.public_key_openssh
}

resource "local_file" "ssh_private_key" {
  content         = tls_private_key.gitops.private_key_pem
  filename        = "/home/ec2-user/.ssh/gitops_ssh.pem"
  file_permission = "0400"
}

resource "local_file" "ssh_config" {
  content         = <<-EOF
    Host git-codecommit.*.amazonaws.com
      User ${aws_iam_user_ssh_key.gitops.id}
      IdentityFile ~/.ssh/gitops_ssh.pem
  EOF
  filename        = "/home/ec2-user/.ssh/config"
  file_permission = "0600"
}

data "aws_iam_policy_document" "gitops_access" {
  statement {
    actions = [
      "codecommit:GitPull",
      "codecommit:GitPush",
    ]
    effect    = "Allow"
    resources = [aws_codecommit_repository.argocd.arn]
  }
}

resource "aws_iam_policy" "gitops_access" {
  name   = "${var.addon_context.eks_cluster_id}-gitops"
  path   = "/"
  policy = data.aws_iam_policy_document.gitops_access.json
}

resource "aws_iam_user_policy_attachment" "gitops_access" {
  user       = aws_iam_user.gitops.name
  policy_arn = aws_iam_policy.gitops_access.arn
}
