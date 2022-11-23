---
title: "Provision a new Node Group"
sidebar_position: 20
---

Create an EKS managed node group:

```bash
$ aws eks create-nodegroup --region $AWS_DEFAULT_REGION \
  --cluster-name $EKS_CLUSTER_NAME \
  --nodegroup-name custom-networking \
  --instance-types t3.medium --node-role $MANAGED_NODE_GROUP_IAM_ROLE_ARN \
  --subnets $PRIMARY_SUBNET_1 $PRIMARY_SUBNET_2 $PRIMARY_SUBNET_3 \
  --labels type=customnetworking \
  --scaling-config minSize=1,maxSize=1,desiredSize=1
```

Node group creation takes several minutes. You can wait for the node group creation to complete using this command:

```bash timeout=300
$ aws eks wait nodegroup-active --cluster-name $EKS_CLUSTER_NAME --nodegroup-name custom-networking
```

Once this is complete we can see the new nodes registered in the EKS cluster:

```bash
$ kubectl get nodes -L eks.amazonaws.com/nodegroup
NAME                                         STATUS   ROLES    AGE    VERSION               NODEGROUP
ip-10-42-10-104.us-west-2.compute.internal   Ready    <none>   46m    v1.23.9-eks-ba74326   managed-system-2022111302580566270000001d
ip-10-42-10-14.us-west-2.compute.internal    Ready    <none>   3m9s   v1.23.9-eks-ba74326   custom-networking
ip-10-42-10-212.us-west-2.compute.internal   Ready    <none>   46m    v1.23.9-eks-ba74326   managed-ondemand-2022111302580566000000001b
ip-10-42-12-155.us-west-2.compute.internal   Ready    <none>   46m    v1.23.9-eks-ba74326   managed-ondemand-2022111302580566000000001b
```

You can see that 1 new node provisioned labeled with the name of the new node group.
