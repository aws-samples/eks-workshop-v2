resource "aws_iam_policy" "fsxn-csi-policy" {
  name        = "AmazonFSXNCSIDriverPolicy"
  description = "FSxN CSI Driver Policy"


  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "fsx:DescribeFileSystems",
                "fsx:DescribeVolumes",
                "fsx:CreateVolume",
                "fsx:RestoreVolumeFromSnapshot",
                "fsx:DescribeStorageVirtualMachines",
                "fsx:UntagResource",
                "fsx:UpdateVolume",
                "fsx:TagResource",
                "fsx:DeleteVolume"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": "secretsmanager:GetSecretValue",
            "Resource": "${aws_secretsmanager_secret.fsxn_password_secret.arn}"
        }
    ]
    })
}


module "iam_iam-role-for-service-accounts-eks" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.37.1"

  role_name              = "AmazonEKS_FSXN_CSI_DriverRole"
  allow_self_assume_role = true

  oidc_providers = {
    eks = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["${local.k8s_service_account_namespace}:${local.k8s_service_account_name}"]
    }
  }

  role_policy_arns = {
    additional           = aws_iam_policy.fsxn-csi-policy.arn
  }

}

locals {
    k8s_service_account_namespace = "trident"
    k8s_service_account_name      = "trident-controller"
}

resource "aws_secretsmanager_secret" "fsxn_password_secret" {
  name = "fsxn_password_secret"
  description = "FSxN CSI Driver Password"
}

resource "aws_secretsmanager_secret_version" "fsxn_password_secret" {
    secret_id     = aws_secretsmanager_secret.fsxn_password_secret.id
    secret_string = jsonencode({
    username = "vsadmin"
    password = "${random_string.fsx_password.result}"
  })
}

data "aws_vpc" "selected_vpc_fsx" {
  tags = {
    created-by = "eks-workshop-v2"
    env        = var.addon_context.eks_cluster_id
  }
}

data "aws_subnets" "private_subnets_fsx" {
  tags = {
    created-by = "eks-workshop-v2"
    env        = var.addon_context.eks_cluster_id
  }

  filter {
    name   = "tag:Name"
    values = ["*Private*"]
  }
}

resource "random_string" "fsx_password" {
  length  = 10
  special = false
}

data "aws_route_table" "private" {
  count = length(data.aws_subnets.private_subnets_fsx.ids)

  vpc_id    = data.aws_vpc.selected_vpc_fsx.id
  subnet_id = data.aws_subnets.private_subnets_fsx.ids[count.index]
}

resource "aws_fsx_ontap_file_system" "fsxnassets" {
  storage_capacity    = 2048
  subnet_ids          = slice(data.aws_subnets.private_subnets_fsx.ids, 0, 2)
  deployment_type     = "MULTI_AZ_1"
  throughput_capacity = 512
  preferred_subnet_id = data.aws_subnets.private_subnets_fsx.ids[0]
  security_group_ids  = [aws_security_group.fsxn.id]
  fsx_admin_password  = random_string.fsx_password.result
  route_table_ids     = [for rt in data.aws_route_table.private : rt.id]

  tags = merge(
    var.tags,
    {
      Name = "${var.addon_context.eks_cluster_id}-fsxn-assets"
    }
  )
}

resource "aws_fsx_ontap_storage_virtual_machine" "fsxnsvm" {
  file_system_id = aws_fsx_ontap_file_system.fsxnassets.id
  name           = "fsxnsvm"
}

resource "aws_security_group" "fsxn" {
  name_prefix = "security group for fsx access"
  vpc_id      = data.aws_vpc.selected_vpc_fsx.id
  tags = merge(
    var.tags,
    {
      Name = "${var.addon_context.eks_cluster_id}-fsxnsecuritygroup"
    }
  )
}

resource "aws_security_group_rule" "fsxn_inbound" {
  description       = "allow inbound traffic to eks"
  from_port         = 0
  protocol          = "-1"
  to_port           = 0
  security_group_id = aws_security_group.fsxn.id
  type              = "ingress"
  cidr_blocks       = [data.aws_vpc.selected_vpc_fsx.cidr_block]
}

resource "aws_security_group_rule" "fsxn_outbound" {
  description       = "allow outbound traffic to anywhere"
  from_port         = 0
  protocol          = "-1"
  security_group_id = aws_security_group.fsxn.id
  to_port           = 0
  type              = "egress"
  cidr_blocks       = [data.aws_vpc.selected_vpc_fsx.cidr_block]
}