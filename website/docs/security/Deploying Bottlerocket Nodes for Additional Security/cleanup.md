---
title: "Clean Up"
sidebar_position: 55
---


1. Use Kustomize to change this configuration to delete carts application from the bottlerocket worker nodes:

```bash
$ kubectl delete -k /workspace/modules/security/bottlerocket
```

2. Remove the bottlerocket nodes using the following aws cli command:

```bash
$ aws eks delete-nodegroup --cluster-name eks-workshop-cluster --nodegroup-name btl-x86 --region us-east-1
```

