output "environment_variables" {
  description = "Environment variables to be added to the IDE shell"
  value = {
    AIML_NEURON_ROLE_ARN    = module.iam_assumable_role_inference.iam_role_arn
    AIML_NEURON_BUCKET_NAME = resource.aws_s3_bucket.inference.id
    AIML_SUBNETS            = "${data.aws_subnets.private.ids[0]},${data.aws_subnets.private.ids[1]},${data.aws_subnets.private.ids[2]}"
    KARPENTER_NODE_ROLE     = module.karpenter.node_iam_role_name
    KARPENTER_ARN           = module.karpenter.node_iam_role_arn
    AIML_DL_TRN_IMAGE       = "public.ecr.aws/neuron/pytorch-training-neuronx:2.1.2-neuronx-py310-sdk2.20.0-ubuntu20.04"
    AIML_DL_INF_IMAGE       = "public.ecr.aws/neuron/pytorch-inference-neuronx:2.1.2-neuronx-py310-sdk2.20.0-ubuntu20.04"
  }
}
