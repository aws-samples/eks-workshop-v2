---
title: "Launch Bottlerocket"
sidebar_position: 50
---

## Add Bottlerocket nodes to an EKS cluster

Insert the following json in managed_node_groups section into the file “/eks-workshop-v2/terraform/modules/cluster/eks.tf”:

```
    #bottlerocket
    bottlerocket_x86 = {
      # 1> Node Group configuration - Part1
      node_group_name        = "btl-x86"      # Max 40 characters for node group name
      create_launch_template = true           # false will use the default launch template
      launch_template_os     = "bottlerocket" # amazonlinux2eks or bottlerocket
      public_ip              = false          # Use this to enable public IP for EC2 instances; only for public subnets used in launch templates ;
      # 2> Node Group scaling configuration
      desired_size    = 2
      max_size        = 2
      min_size        = 2
      max_unavailable = 1 # or percentage = 20

      # 3> Node Group compute configuration
      ami_type       = "BOTTLEROCKET_x86_64" # AL2_x86_64, AL2_x86_64_GPU, AL2_ARM_64, CUSTOM, BOTTLEROCKET_ARM_64, BOTTLEROCKET_x86_64
      capacity_type  = "ON_DEMAND"           # ON_DEMAND or SPOT
      instance_types = ["m5.large"]          # List of instances to get capacity from multipe pools
      block_device_mappings = [
        {
          device_name = "/dev/xvda"
          volume_type = "gp3"
          volume_size = 100
        }
      ]
      
      # 4> Node Group network configuration
      subnet_ids = [] # Defaults to private subnet-ids used by EKS Controle plane. Define your private/public subnets list with comma separated subnet_ids  = ['subnet1','subnet2','subnet3']

      k8s_taints = []

      k8s_labels = {
        role        = "bottlerocket" }
      }
      additional_tags = {
        ExtraTag    = "m5x-on-demand"
        Name        = "m5x-on-demand"
        subnet_type = "private"
      }
      launch_template_tags = {
        SomeAwsProviderDefaultTag1: "TRUE"
        SomeAwsProviderDefaultTag2: "TRUE"
      }
    }
```

Create bottlerocket infrastrucutre using eks-workshop-v2 cmd prompt:

```bash
$ make create-infrastructure
```

Output:

```bash
$ kubectl get nodes -l eks.amazonaws.com/nodegroup-image=ami-0377306a8f776c503
NAME                           STATUS   ROLES    AGE    VERSION
ip-10-42-10-115.ec2.internal   Ready    <none>   157m   v1.23.12-eks-a64d4ad
ip-10-42-12-32.ec2.internal    Ready    <none>   157m   v1.23.12-eks-a64d4ad
```

## Congratulations!

You now have a fully working Amazon EKS Cluster with Bottlerocket nodes that is ready to use!