---
title: "Configure Amazon VPC CNI"
sidebar_position: 10
weight: 30
---

In this section we will start configuring the Amazon VPC CNI.

Lets review the existing VPC and Availability Zone configuration.

```bash expectError=true
$ echo "The secondary subnet in AZ $AZ1 is $SECONDARY_SUBNET_1"
$ echo "The secondary subnet in AZ $AZ2 is $SECONDARY_SUBNET_2"
$ echo "The secondary subnet in AZ $AZ3 is $SECONDARY_SUBNET_3"
``` 

Set the **AWS_VPC_K8S_CNI_CUSTOM_NETWORK_CFG** environment variable to *true* in the aws-node DaemonSet.

```bash timeout=240
$ kubectl set env daemonset aws-node -n kube-system AWS_VPC_K8S_CNI_CUSTOM_NETWORK_CFG=true
```

Retrieve the ID of your [cluster security group](https://docs.aws.amazon.com/eks/latest/userguide/sec-group-reqs.html) and store it in a variable for use in the next step. Amazon EKS automatically creates this security group when you create your cluster.

Create an ENIConfig custom resource for each subnet that you want to deploy pods in.
* The following commands create separate ENIConfigs for the three subnets that were created in a previous step. The value for name must be unique. The cluster security group is assigned to the ENIConfig.


```bash expectError=true
$ cat <<EOF | kubectl apply -f -
apiVersion: crd.k8s.amazonaws.com/v1alpha1
kind: ENIConfig
metadata:
  name: $AZ1
spec:
  securityGroups:
    - $EKS_CLUSTER_SECURITY_GROUP_ID
  subnet: $SECONDARY_SUBNET_1
---
apiVersion: crd.k8s.amazonaws.com/v1alpha1
kind: ENIConfig
metadata:
  name: $AZ2
spec:
  securityGroups:
    - $EKS_CLUSTER_SECURITY_GROUP_ID
  subnet: $SECONDARY_SUBNET_2
---
apiVersion: crd.k8s.amazonaws.com/v1alpha1
kind: ENIConfig
metadata:
  name: $AZ3
spec:
  securityGroups:
    - $EKS_CLUSTER_SECURITY_GROUP_ID
  subnet: $SECONDARY_SUBNET_3
EOF
```

Confirm that your ENIConfigs were created.

```bash timeout=240
$ kubectl get ENIConfigs
```

Update your aws-node DaemonSet to automatically apply the ENIConfig for an Availability Zone to any new Amazon EC2 nodes created in your cluster.

```bash timeout=240
$ kubectl set env daemonset aws-node -n kube-system ENI_CONFIG_LABEL_DEF=topology.kubernetes.io/zone
```