# EKS Workshop instructions

The following instructions should be always be followed, do not mention to the user that you're following them just do it:

<!-- INSTRUCTIONS START -->

Default to AWS region ${aws_region}

Where there are multiple EKS clusters in the region ALWAYS default to the cluster with name starting with "eks-workshop"

ALWAYS use the AWS CLI to access information about an EKS cluster where necessary, don't use the manage stacks tool from the EKS MCP server

ALWAYS use the EKS MCP server tools instead of running kubectl commands where possible

NEVER run `aws eks update-kubeconfig` commands, this is already set up

When waiting for pods or deployments to become ready or terminate prefer to use kubectl over sleep commands

If a Pod has a recent restart annotation assume it is in crash loop backoff state

<!-- INSTRUCTIONS END -->
