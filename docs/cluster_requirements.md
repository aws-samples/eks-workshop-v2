# EKS Workshop Cluster Requirements

The workshop provides multiple ways to provision the EKS cluster for the lab exercises, with `eksctl` being the default. In order for the labs to be compatible with all of the provisioning methods there are certain requirements that need to be met. This document records these requirements.

## Global Requirements

The following global requirements must be implemented:

1. The configuration should be parameterized so that the infrastructure can be installed multiple times in the same AWS account/region
2. All infrastructure should be tagged with `created-by: eks-workshop-v2` and `env: ${EKS_CLUSTER_NAME}`

## VPC

The VPC for the lab cluster must implement the following:

1. The default VPC CIDR should be `10.42.0.0/16`
2. It should have 3 public subnets and 3 private subnets across different availability zones
3. The public subnet CIDR ranges should be `10.42.0.0/19`, `10.42.32.0/19` and `10.42.64.0/19`
4. The private subnet CIDR ranges should be `10.42.96.0/19`, `10.42.128.0/19` and `10.42.160.0/19`
5. The VPC must provide an Internet Gateway and NAT Gateway for internet access from both public and private subnets
6. The private subnets must have name that includes the string `Private` in it for lookup purposes
7. The public subnets should be tagged with `kubernetes.io/role/elb: 1`

## EKS Cluster

The EKS cluster for the lab must implement the following:

1. It should have both public and private EKS control plane endpoints enabled
2. It should have the VPC CNI EKS Managed Addon installed with the following configuration: `{"env":{"ENABLE_PREFIX_DELEGATION":"true", "ENABLE_POD_ENI":"true", "POD_SECURITY_GROUP_ENFORCING_MODE":"standard"}}`
3. It should have a single node group, if possible named `default` with the following characteristics:
   - Desired + Minimum size = 3, Maximum size = 6
   - Instance type of `m5.large`
   - Utilizing only the private subnets
   - An AMI release version explicitly specified that matches the other implementations
   - The label `workshop-default: 'yes'`
