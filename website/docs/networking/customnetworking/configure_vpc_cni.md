---
title: "Configure Amazon VPC CNI"
sidebar_position: 10
weight: 30
---

In this section we will start configuring the Amazon VPC CNI.

Define variables with the values of the private subnet IDs

```bash expectError=true
$ subnetlist=`aws ec2 describe-subnets  --filters "Name=cidr-block,Values=100.64.*" \ 
  --query 'Subnets[*].[AvailabilityZone,SubnetId]' --output json`

$ az_1=`echo $subnetlist | jq -r '.[0][0]'`
$ new_subnet_id_1=`echo $subnetlist | jq -r '.[0][1]'`


$ az_2=`echo $subnetlist | jq -r '.[1][0]'`
$ new_subnet_id_2=`echo $subnetlist | jq -r '.[1][1]'`


$ az_3=`echo $subnetlist | jq -r '.[2][0]'`
$ new_subnet_id_3=`echo $subnetlist | jq -r '.[2][1]'`
```

Set the AWS_VPC_K8S_CNI_CUSTOM_NETWORK_CFG environment variable to *true* in the aws-node DaemonSet.

```bash timeout=240
$ kubectl set env daemonset aws-node -n kube-system AWS_VPC_K8S_CNI_CUSTOM_NETWORK_CFG=true
```

Retrieve the ID of your [cluster security group](https://docs.aws.amazon.com/eks/latest/userguide/sec-group-reqs.html) and store it in a variable for use in the next step. Amazon EKS automatically creates this security group when you create your cluster.


```bash expectError=true
$ region_code=$AWS_REGION
$ cluster_name=eks-workshop-cluster
$ cluster_security_group_id=$(aws eks describe-cluster --name $cluster_name \
  --query cluster.resourcesVpcConfig.clusterSecurityGroupId --output text)
```

Create an ENIConfig custom resource for each subnet that you want to deploy pods in.
* Create a unique file for each network interface configuration.
* The following commands create separate ENIConfig files for the two subnets that were created in a previous step. The value for name must be unique. The name is the same as the Availability Zone that the subnet is in. The cluster security group is assigned to the ENIConfig.


```bash expectError=true
$ cat >$az_1.yaml <<EOF
apiVersion: crd.k8s.amazonaws.com/v1alpha1
kind: ENIConfig
metadata:
  name: $az_1
spec:
  securityGroups:
    - $cluster_security_group_id
  subnet: $new_subnet_id_1
EOF
```

```bash expectError=true
$ cat >$az_2.yaml <<EOF
apiVersion: crd.k8s.amazonaws.com/v1alpha1
kind: ENIConfig
metadata:
  name: $az_2
spec:
  securityGroups:
    - $cluster_security_group_id
  subnet: $new_subnet_id_2
EOF
```


```bash expectError=true
$ cat >$az_3.yaml <<EOF
apiVersion: crd.k8s.amazonaws.com/v1alpha1
kind: ENIConfig
metadata:
  name: $az_3
spec:
  securityGroups:
    - $cluster_security_group_id
  subnet: $new_subnet_id_3
EOF
```

Apply each custom resource file that you created to your cluster with the following commands.

```bash timeout=240
$ kubectl apply -f $az_1.yaml
$ kubectl apply -f $az_2.yaml
$ kubectl apply -f $az_3.yaml
```

Confirm that your ENIConfigs were created.

```bash timeout=240
$ kubectl get ENIConfigs
```

Confirm that your ENIConfigs were created.

```bash timeout=240
$ kubectl get ENIConfigs
```

The example output is as follows.

[TODO] - Add command output here instead of using an image.


Update your aws-node DaemonSet to automatically apply the ENIConfig for an Availability Zone to any new Amazon EC2 nodes created in your cluster.

```bash timeout=240
$ kubectl set env daemonset aws-node -n kube-system ENI_CONFIG_LABEL_DEF=topology.kubernetes.io/zone
```