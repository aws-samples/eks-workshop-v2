data "aws_vpc" "this" {
  tags = {
    created-by = "eks-workshop-v2"
    env        = local.addon_context.eks_cluster_id
  }
}

resource "aws_security_group_rule" "dns_udp" {
  type              = "ingress"
  from_port         = 53
  to_port           = 53
  protocol          = "udp"
  cidr_blocks       = [data.aws_vpc.this.cidr_block]
  security_group_id = data.aws_eks_cluster.eks_cluster.vpc_config[0].cluster_security_group_id
}

resource "aws_security_group_rule" "dns_tcp" {
  type              = "ingress"
  from_port         = 53
  to_port           = 53
  protocol          = "tcp"
  cidr_blocks       = [data.aws_vpc.this.cidr_block]
  security_group_id = data.aws_eks_cluster.eks_cluster.vpc_config[0].cluster_security_group_id
}

output "environment" {
  value = <<EOF
export VPC_ID=${data.aws_vpc.this.id}
EOF
}
