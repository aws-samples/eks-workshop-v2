data "aws_region" "current" {}


module "cluster" {
  source = "../modules/cluster"

  id = var.id

  map_roles = [{
    rolearn  = module.ide.cloud9_iam_role
    username = "cloud9"
    groups   = ["system:masters"]
  }]
}

resource "aws_s3_bucket" "eks_workshop_bootstrap" {
  bucket        = "${module.cluster.eks_cluster_id}-bootstrap"
  force_destroy = true
}

data "archive_file" "bootstrap" {
  type        = "zip"
  source_dir  = "${path.module}/../../environment"
  output_path = "/tmp/eks-workshop-bootstrap-scripts.zip"
}

resource "aws_s3_object" "bootstrap_archive" {
  bucket = aws_s3_bucket.eks_workshop_bootstrap.bucket
  key    = "bootstrap.zip"
  source = data.archive_file.bootstrap.output_path
  etag   = filemd5(data.archive_file.bootstrap.output_path)
}

module "ide" {
  source = "../modules/ide"

  environment_name = module.cluster.eks_cluster_id
  subnet_id        = module.cluster.public_subnet_ids[0]
  additional_cloud9_policies = [{
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:HeadObject",
          "s3:ListBucket",
          "s3:GetObject*"
        ],
        Resource = [
          "arn:aws:s3:::${aws_s3_bucket.eks_workshop_bootstrap.bucket}",
          "arn:aws:s3:::${aws_s3_bucket.eks_workshop_bootstrap.bucket}/*"
        ]
      }
    ]
    }, {
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "eks:*",
          "ssm:GetParameter"
        ],
        Resource = [
          "*"
        ]
      }
    ]
  }]

  cloud9_user_arns = var.cloud9_user_arns

  bootstrap_script = <<EOF
mkdir -p /tmp/bootstrap
cd /tmp/bootstrap
aws s3 cp --quiet s3://${aws_s3_bucket.eks_workshop_bootstrap.bucket}/${aws_s3_object.bootstrap_archive.key} .
unzip -o ${aws_s3_object.bootstrap_archive.key}
chmod +x install-tools.sh
./install-tools.sh
rm -f /tmp/bootstrap/*
cat << EOT > /home/ec2-user/.bashrc
if [ ! -f ~/.kube/config ]; then
  aws eks update-kubeconfig --name ${module.cluster.eks_cluster_id} --region ${data.aws_region.current.id}
fi
EOT
echo "AWS_DEFAULT_REGION=${data.aws_region.current.id}" >> /etc/profile
EOF
}

