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

# The EKS Capability for Argo CD authenticates users through IAM Identity Center,
# so the account needs an Identity Center instance holding an Argo CD admin user
# before the capability can be created.
#
# This lab only ever reads from Identity Center. It never creates the instance and
# never creates the user, because both are writes to an account-wide directory that
# may hold real identities. Workshop Studio events get them from `preprovision/`,
# which the Workshop Studio provisioning pipeline applies and `prepare-environment`
# does not. Everyone else creates them once themselves, as the lab introduction
# describes.
data "aws_ssoadmin_instances" "main" {}

locals {
  idc_instance_arns     = tolist(data.aws_ssoadmin_instances.main.arns)
  idc_identity_store_id = try(tolist(data.aws_ssoadmin_instances.main.identity_store_ids)[0], "")
  idc_instance_arn      = try(local.idc_instance_arns[0], "")
  idc_user_name         = "eks-workshop"

  # Identity Center does not require the sign-in name to be an email address, so the
  # user name stays short and memorable for participants to type. The directory still
  # wants a primary email, and nothing ever delivers to it, so use the address range
  # RFC 2606 reserves for documentation.
  idc_user_email = "eks-workshop@example.com"

  # The console deep link uses the instance ID without its "ssoins-" prefix.
  idc_instance_id = trimprefix(try(element(split("/", local.idc_instance_arn), 1), ""), "ssoins-")
  idc_console_url = "https://${data.aws_region.current.id}.console.aws.amazon.com/singlesignon/home?region=${data.aws_region.current.id}#/instances/${local.idc_instance_id}/users"

  # Empty when the user has not been activated for us, which is the signal the docs
  # use to send people down the manual one-time password route.
  idc_password = try(
    jsondecode(data.aws_secretsmanager_secret_version.argocd_admin[0].secret_string).password,
    ""
  )
}

# Checks the provider cannot express. `aws_ssoadmin_instances` returns only ARNs
# and identity store IDs, so telling an account instance apart from a shared
# organization instance, and confirming the workshop user exists, needs API calls
# the AWS provider does not surface.
resource "null_resource" "idc_precheck" {
  triggers = {
    region    = data.aws_region.current.id
    user_name = local.idc_user_name
  }

  provisioner "local-exec" {
    command = "bash ${path.module}/idc-precheck.sh"

    environment = {
      REGION     = data.aws_region.current.id
      ACCOUNT    = data.aws_caller_identity.current.account_id
      USER_NAME  = local.idc_user_name
      USER_EMAIL = local.idc_user_email
    }
  }

  lifecycle {
    precondition {
      condition     = length(local.idc_instance_arns) > 0
      error_message = "No IAM Identity Center instance found in this account and Region. This lab does not set one up for you. See \"Prerequisites - IAM Identity Center\" in the lab introduction: https://www.eksworkshop.com/docs/automation/gitops/argocd/"
    }
  }
}

data "aws_identitystore_user" "argocd_admin" {
  depends_on = [null_resource.idc_precheck]

  identity_store_id = local.idc_identity_store_id

  alternate_identifier {
    unique_attribute {
      attribute_path  = "UserName"
      attribute_value = local.idc_user_name
    }
  }
}

# At an AWS-run event the pre-provisioning pipeline has already activated this user
# and stored a password it proved works, so participants can be handed a working
# credential instead of minting a one-time password themselves.
#
# Gated on resources_precreated because that is this repo's existing signal for
# "Workshop Studio pre-provisioned things", and the pre-provisioning is precisely
# what creates this secret. Anywhere else it does not exist, and the lab falls back
# to the manual activation the docs describe.
data "aws_secretsmanager_secret_version" "argocd_admin" {
  count = var.resources_precreated ? 1 : 0

  secret_id = "${var.eks_cluster_id}-argocd-idc"
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
    data.aws_identitystore_user.argocd_admin,
  ]

  cluster_name              = var.addon_context.eks_cluster_id
  capability_name           = "argocd"
  type                      = "ARGOCD"
  role_arn                  = aws_iam_role.argocd_capability.arn
  delete_propagation_policy = "RETAIN"

  configuration {
    argo_cd {
      aws_idc {
        idc_instance_arn = local.idc_instance_arn
        idc_region       = data.aws_region.current.id
      }

      rbac_role_mapping {
        role = "ADMIN"
        identity {
          id   = data.aws_identitystore_user.argocd_admin.user_id
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
