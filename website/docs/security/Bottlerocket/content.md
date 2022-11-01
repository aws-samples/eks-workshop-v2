---
title: "Bottlerocket"
sidebar_position: 50
---

Bottlerocket managed node groups in Amazon EKS enables you to run your applications on container-optimized managed nodes with enhanced security. Bottlerocket is now a built-in managed node group [Amazon Machine Image](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AMIs.html) (AMI) option, enabling you to provision container-optimized nodes with a single click. You can leverage existing managed node group notification mechanisms to make updates when newer Amazon EKS Bottlerocket AMIs become available. You can also recycle nodes periodically to standardize management across different node group types.

## Command to find the Latest Bottlerocket AMI in us-east-1 region:

```
aws ssm get-parameter --region us-east-1 --name "/aws/service/bottlerocket/aws-k8s-1.23/x86_64/latest/image_id" --query Parameter.Value --output text
```

## Output:

```
ami-0377306a8f776c503
```

* *Note*: Verify the region and version in the above command to get the appropriate Bottleorcket AMI.*

All of the existing Amazon EKS [managed node update behavior](https://docs.aws.amazon.com/eks/latest/userguide/managed-node-update-behavior.html) now applies to Bottlerocket as well. With managed node group support for Bottlerocket, you can now minimize downtime for your workloads caused by simultaneous node upgrades. You can do this by specifying the maximum number of nodes that can become unavailable during an upgrade in the maxUnavailable field of a node group’s [updateConfig](https://docs.aws.amazon.com/eks/latest/APIReference/API_UpdateNodegroupConfig.html). Alternatively, you can select maxUnavailablePercentage, which specifies the maximum number of unavailable nodes as a percentage of the total number of nodes. You can use this to determine the maximum number of instances that will be brought down simultaneously. 

To spin up Bottlerocket nodes for the e-commerce “Carts” application you will need to insert the following json in managed_node_groups section into the file “/eks-workshop-v2/terraform/modules/cluster/eks.tf”:

``` #bottlerocket
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
        Environment = "workshop"
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

## Run the following command after returning the eks-workshop-v2 cmd prompt:

```
make create-infrastructure
```

## Output:

```
kubectl get nodes -l eks.amazonaws.com/nodegroup-image=ami-0377306a8f776c503
NAME                           STATUS   ROLES    AGE    VERSION
ip-10-42-10-115.ec2.internal   Ready    <none>   157m   v1.23.12-eks-a64d4ad
ip-10-42-12-32.ec2.internal    Ready    <none>   157m   v1.23.12-eks-a64d4ad
```

## Run the following command to look where cart application pods are running currently:

```
kubectl get pod -o=custom-columns=NODE:.spec.nodeName,NAME:.metadata.name --all-namespaces
```

## Run the following command to drain all the cart application pods from the AL2 and move them to Bottlerocket nodes:

```
kubectl drain ip-10-42-10-187.ec2.internal ip-10-42-10-194.ec2.internal ip-10-42-12-107.ec2.internal  --ignore-daemonsets --force
node/ip-10-42-10-187.ec2.internal already cordoned
node/ip-10-42-10-194.ec2.internal already cordoned
node/ip-10-42-12-107.ec2.internal already cordoned
```

* *Note*: Pods not managed by ReplicationController, ReplicaSet, Job, DaemonSet or StatefulSet will be deleted *

Now as the SchedulingDisabled on the Amazon Linux nodes the carts application pods will be hosted on the Bottlerocket nodes. Bottlerocket is built from the ground up with only the minimum components necessary to run containers installed on the host. Any additional software, such as monitoring agents or metric collection systems like Container Insights, Prometheus, or Open Telemetry, must be run as Daemonsets. Bottlerocket also recommends using static pods or host containers.

## Run the make serve command to open the application in browser or localhost:

```
make serve
```

Additionally, if you want to modify the host, we recommend that you use [bootstrap containers](https://github.com/bottlerocket-os/bottlerocket/tree/1.2.x#bootstrap-containers-settings) for Bottlerocket. Bootstrap containers are host containers that can be used to initialize the host before the launch of services such as Kubernetes. Bootstrap containers are quite similar to standard host containers (control and admin); they have persistent storage and the ability to store optional user data. Bootstrap containers have access to the host’s root filesystem and all devices, and are configured with the `CAP_SYS_ADMIN` capability. This allows bootstrap containers to generate visible files, directories, and mounts on the host. Before the boot script is executed, the bootstrap containers are executed. You can utilize the launch template and user data to configure bootstrap containers by following the procedures outlined here. Please refer to the Amazon EKS user guide for additional information on [how to use launch template](https://docs.aws.amazon.com/eks/latest/userguide/launch-templates.html) with Bottlerocket nodes.

## Cleanup:

```
1. Remove the Bottlerocket json section from the eks.tf file in the directory eks-workshop-v2/terraform/modules/cluster/
2. Uncordon all the Amazon Linux 2 nodes using the “kubectl uncordon ip-10-42-10-187.ec2.internal ip-10-42-10-194.ec2.internal ip-10-42-12-107.ec2.internal” which will enable scheduling on the AL2 nodes.
3. Manually delete the Bottlerocket managed node group from the AWS EKS console.
```

[terraform-aws-eks-blueprints](https://github.com/aws-ia/terraform-aws-eks-blueprints/blob/a75e22b198c881a5d697cc74a4ba4586a5d0491d/docs/node-groups.md)
[bottlerocket-with-managed_node_groups](https://aws.amazon.com/blogs/containers/amazon-eks-adds-native-support-for-bottlerocket-in-managed-node-groups/)

