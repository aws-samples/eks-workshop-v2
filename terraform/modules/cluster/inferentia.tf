resource "aws_s3_bucket" "inference" {
  bucket_prefix = "eksworkshop-inference"
  force_destroy = true
  //タグの設定
  tags = {
    Name = "eksworkshop-inference"
  }
}

module "iam_assumable_role_inference" {
  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "~> v5.3.0"
  create_role                   = true
  role_name                     = "${var.environment_name}-inference"
  provider_url                  = module.eks_blueprints.eks_oidc_issuer_url
  role_policy_arns              = [aws_iam_policy.inference.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:aiml:inference"]
}

resource "aws_iam_policy" "inference" {
  name        = "${var.environment_name}-inference"
  path        = "/"
  description = "IAM policy for the inferenct workload"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "s3:*",
      "Resource": [
        "arn:aws:s3:::${aws_s3_bucket.inference.id}",
        "arn:aws:s3:::${aws_s3_bucket.inference.id}/*"
      ]
    }
  ]
}
EOF
}

data "http" "neuron_device_plugin_rbac_manifest" {
  url = "https://raw.githubusercontent.com/aws-neuron/aws-neuron-sdk/v2.6.0/src/k8/k8s-neuron-device-plugin-rbac.yml"
}

data "http" "neuron_device_plugin_manifest" {
  url = "https://raw.githubusercontent.com/aws-neuron/aws-neuron-sdk/v2.6.0/src/k8/k8s-neuron-device-plugin.yml"
}

data "kubectl_file_documents" "neuron_device_plugin_rbac_doc" {
  content = data.http.neuron_device_plugin_rbac_manifest.response_body
}

data "kubectl_file_documents" "neuron_device_plugin_doc" {
  content = data.http.neuron_device_plugin_manifest.response_body
}

resource "kubectl_manifest" "neuron_device_plugin_rbac" {
  for_each  = data.kubectl_file_documents.neuron_device_plugin_rbac_doc.manifests
  yaml_body = each.value
}

resource "kubectl_manifest" "neuron_device_plugin" {
  for_each  = data.kubectl_file_documents.neuron_device_plugin_doc.manifests
  yaml_body = each.value
}
