---
title: Cleanup
sidebar_position: 30
---

The following commands can be used to the lab environment is cleaned up after the Taints module. 

1. Remove the configured taint on the tainted node group. Notice the `removeTaints` value passed to the `taints` parameter:

```bash
$ aws eks update-nodegroup-config \
    --cluster-name $EKS_CLUSTER_NAME \
    --nodegroup-name $EKS_TAINTED_MNG_NAME \
    --taints "removeTaints=[{key=frontend, value=true, effect=NO_EXECUTE}]"
```
2. Restore the UI service to its default configuration

```bash
$ kubectl apply -k /workspace/manifests/ui
```