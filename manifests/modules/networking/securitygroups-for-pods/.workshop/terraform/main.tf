data "aws_vpc" "this" {
  tags = {
    created-by = "eks-workshop-v2"
    env        = var.addon_context.eks_cluster_id
  }
}

resource "aws_security_group_rule" "dns_udp" {
  type              = "ingress"
  from_port         = 53
  to_port           = 53
  protocol          = "udp"
  cidr_blocks       = [data.aws_vpc.this.cidr_block]
  security_group_id = var.cluster_security_group_id
}

resource "aws_security_group_rule" "dns_tcp" {
  type              = "ingress"
  from_port         = 53
  to_port           = 53
  protocol          = "tcp"
  cidr_blocks       = [data.aws_vpc.this.cidr_block]
  security_group_id = var.cluster_security_group_id
}

module "preprovision" {
  source = "./preprovision"
  count  = var.resources_precreated ? 0 : 1

  eks_cluster_id = var.eks_cluster_id
  tags           = var.tags
}