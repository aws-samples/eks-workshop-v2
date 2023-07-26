---
title: "Configure Karpenter"
sidebar_position: 20
---

Karpenter has been installed in our EKS cluster, and runs as a deployment:

```bash
$ kubectl get deployment -n karpenter
NAME        READY   UP-TO-DATE   AVAILABLE   AGE
karpenter   2/2     2            2           105s
```

The only setup that we will need to do is to update our EKS IAM mappings to allow Karpenter nodes to join the cluster:

```bash
$ eksctl create iamidentitymapping --cluster $EKS_CLUSTER_NAME \
    --region=$AWS_REGION --arn $KARPENTER_NODE_ROLE \
    --group system:bootstrappers --group system:nodes \
    --username system:node:{{EC2PrivateDNSName}}
```
