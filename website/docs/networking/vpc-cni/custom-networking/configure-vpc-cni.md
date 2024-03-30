---
title: "Configure Amazon VPC CNI"
sidebar_position: 10
---

We'll start by configuring the Amazon VPC CNI. Our VPC has been reconfigured with the addition of a secondary CIDR with the range `100.64.0.0/16`:

```bash
$ aws ec2 describe-vpcs --vpc-ids $VPC_ID | jq '.Vpcs[0].CidrBlockAssociationSet'
[
  {
    "AssociationId": "vpc-cidr-assoc-0ef3fae4a0abc4a42",
    "CidrBlock": "10.42.0.0/16",
    "CidrBlockState": {
      "State": "associated"
    }
  },
  {
    "AssociationId": "vpc-cidr-assoc-0a6577e1404081aef",
    "CidrBlock": "100.64.0.0/16",
    "CidrBlockState": {
      "State": "associated"
    }
  }
]
```

This means that we now have a separate CIDR range we can use in addition to the default CIDR range, which in the above output is `10.42.0.0/16`. From this new CIDR range we have added 3 new subnets to the VPC which will be used for running our pods:

```bash
$ echo "The secondary subnet in AZ $SUBNET_AZ_1 is $SECONDARY_SUBNET_1"
$ echo "The secondary subnet in AZ $SUBNET_AZ_2 is $SECONDARY_SUBNET_2"
$ echo "The secondary subnet in AZ $SUBNET_AZ_3 is $SECONDARY_SUBNET_3"
```

To enable custom networking we have to set the `AWS_VPC_K8S_CNI_CUSTOM_NETWORK_CFG` environment variable to _true_ in the aws-node DaemonSet.

```bash wait=60
$ kubectl set env daemonset aws-node -n kube-system AWS_VPC_K8S_CNI_CUSTOM_NETWORK_CFG=true
```

Then we'll create an `ENIConfig` custom resource for each subnet that pods will be deployed in:

```file
manifests/modules/networking/custom-networking/provision/eniconfigs.yaml
```

Let's apply these to our cluster:

```bash wait=30
$ kubectl kustomize ~/environment/eks-workshop/modules/networking/custom-networking/provision \
  | envsubst | kubectl apply -f-
```

Confirm that the `ENIConfig` objects were created:

```bash
$ kubectl get ENIConfigs
```

Finally we'll update the aws-node DaemonSet to automatically apply the `ENIConfig` for an Availability Zone to any new Amazon EC2 nodes created in the EKS cluster.

```bash wait=60
$ kubectl set env daemonset aws-node -n kube-system ENI_CONFIG_LABEL_DEF=topology.kubernetes.io/zone
```
