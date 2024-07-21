output "environment_variables" {
  description = "Environment variables to be added to the IDE shell"
  value = {
    AIML_NEURON_ROLE_ARN    = module.iam_assumable_role_chatbot.iam_role_arn
    AIML_NEURON_BUCKET_NAME = resource.aws_s3_bucket.chatbot.id
    AIML_DL_IMAGE           = "763104351884.dkr.ecr.${data.aws_region.current.name}.amazonaws.com/pytorch-chatbot-neuron:1.13.1-neuron-py310-sdk2.12.0-ubuntu20.04"
    AIML_SUBNETS            = "${data.aws_subnets.private.ids[0]},${data.aws_subnets.private.ids[1]},${data.aws_subnets.private.ids[2]}"
    KARPENTER_NODE_ROLE     = module.eks_blueprints_addons.karpenter.node_iam_role_name
    KARPENTER_ARN           = module.eks_blueprints_addons.karpenter.node_iam_role_arn
  }
}

#output "subnet_details" {
#value = merge({
#GRAVITON_NODE_ROLE = aws_iam_role.graviton_node.arn
#}, {
#for index, id in data.aws_subnets.private.ids : "PRIMARY_SUBNET_${index + 1}" => id
#})
#}
