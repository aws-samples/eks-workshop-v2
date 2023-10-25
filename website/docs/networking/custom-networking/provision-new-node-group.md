---
title: "Provision a new Node Group"
sidebar_position: 20
---

Create an EKS managed node group:

```bash tags=ipv4 wait=30
$ aws eks create-nodegroup --region $AWS_REGION \
  --cluster-name $EKS_CLUSTER_NAME \
  --nodegroup-name custom-networking \
  --instance-types t3.medium --node-role $CUSTOM_NETWORKING_NODE_ROLE \
  --subnets $PRIMARY_SUBNET_1 $PRIMARY_SUBNET_2 $PRIMARY_SUBNET_3 \
  --labels type=customnetworking \
  --scaling-config minSize=1,maxSize=1,desiredSize=1
```

Node group creation takes several minutes. You can wait for the node group creation to complete using this command:

```bash tags=ipv4 wait=30 timeout=300
$ aws eks wait nodegroup-active --cluster-name $EKS_CLUSTER_NAME --nodegroup-name custom-networking
```

Once this is complete we can see the new nodes registered in the EKS cluster:

```bash tags=ipv4 wait=30
$ kubectl get nodes -L eks.amazonaws.com/nodegroup
NAME                                            STATUS   ROLES    AGE   VERSION               NODEGROUP
ip-10-42-104-242.us-west-2.compute.internal   Ready    <none>   84m   v1.25.6-eks-48e63af   default
ip-10-42-110-28.us-west-2.compute.internal    Ready    <none>   61s   v1.25.9-eks-0a21954   custom-networking
ip-10-42-139-60.us-west-2.compute.internal    Ready    <none>   65m   v1.25.6-eks-48e63af   default
ip-10-42-180-105.us-west-2.compute.internal   Ready    <none>   65m   v1.25.6-eks-48e63af   default
```

You can see that 1 new node provisioned labeled with the name of the new node group.
