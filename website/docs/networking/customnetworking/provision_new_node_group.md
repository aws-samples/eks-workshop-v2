---
title: "Provision a new Node Group"
sidebar_position: 20
weight: 40
---

Create a Managed Node Group

```bash expectError=true
$ aws eks create-nodegroup --region $AWS_DEFAULT_REGION --cluster-name $EKS_CLUSTER_NAME \
  --nodegroup-name custom-networking-nodegroup \
  --instance-types t3.medium --node-role $MANAGED_NODE_GROUP_IAM_ROLE_ARN \
  --subnets $PRIMARY_SUBNET_1 $PRIMARY_SUBNET_2 $PRIMARY_SUBNET_3 \
  --labels type=customnetworking \
  --scaling-config minSize=1,maxSize=1,desiredSize=1
```

Node group creation takes several minutes. You can check the status of the creation of a managed node group with the following command.

```bash expectError=true
$ aws eks describe-nodegroup --cluster-name $EKS_CLUSTER_NAME --nodegroup-name custom-networking-nodegroup --query nodegroup.status --output text
```

Don't continue to the next step until the output returned is ACTIVE.

Get a list of nodes in your cluster

```bash expectError=true
$ kubectl get nodes -o wide
```

Here is a sample output from the previous command.
```bash expectError=true
$ kubectl get nodes -o wide
NAME                                         STATUS   ROLES    AGE     VERSION               INTERNAL-IP    EXTERNAL-IP   OS-IMAGE         KERNEL-VERSION                 CONTAINER-RUNTIME
ip-10-42-10-127.us-west-2.compute.internal   Ready    <none>   2m15s   v1.23.9-eks-ba74326   10.42.10.127   <none>        Amazon Linux 2   5.4.219-126.411.amzn2.x86_64   docker://20.10.17
ip-10-42-10-190.us-west-2.compute.internal   Ready    <none>   60m     v1.23.9-eks-ba74326   10.42.10.190   <none>        Amazon Linux 2   5.4.217-126.408.amzn2.x86_64   docker://20.10.17
ip-10-42-11-189.us-west-2.compute.internal   Ready    <none>   60m     v1.23.9-eks-ba74326   10.42.11.189   <none>        Amazon Linux 2   5.4.217-126.408.amzn2.x86_64   docker://20.10.17
ip-10-42-12-73.us-west-2.compute.internal    Ready    <none>   60m     v1.23.9-eks-ba74326   10.42.12.73    <none>        Amazon Linux 2   5.4.217-126.408.amzn2.x86_64   docker://20.10.17
```

You can see that 1 new node provisioned. You can identity this with the least age.


