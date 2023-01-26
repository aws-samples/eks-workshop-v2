---
title: "Cleanup"
sidebar_position: 30
weight: 60
---

Reset Amazon VPC CNI configuration:

```bash
$ kubectl set env daemonset aws-node -n kube-system AWS_VPC_K8S_CNI_CUSTOM_NETWORK_CFG=false
```

Delete the node group that was created to test custom networking:

```bash timeout=400
$ aws eks delete-nodegroup --region $AWS_DEFAULT_REGION --cluster-name $EKS_CLUSTER_NAME --nodegroup-name custom-networking
$ aws eks wait nodegroup-deleted --cluster-name $EKS_CLUSTER_NAME --nodegroup-name custom-networking
```

Reset checkout back to its default configuration:

```bash
$ kubectl apply -k /workspace/manifests/checkout
$ kubectl rollout status deployment/checkout -n checkout --timeout 180s
```
