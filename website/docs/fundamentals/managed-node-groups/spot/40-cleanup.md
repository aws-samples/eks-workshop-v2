---
title: Cleanup
sidebar_position: 40
---

Cleanup our nginx application

```bash
$ kubectl delete -f nginx-deployment.yaml
deployment.apps "nginx-deployment" deleted

$ rm nginx-deployment.yaml
```

Delete SPOT node group

```bash
$ aws eks delete-nodegroup \
  --cluster-name=${EKS_CLUSTER_NAME} \
  --nodegroup-name ng-spot 
$ aws eks wait nodegroup-deleted \
  --cluster-name=${EKS_CLUSTER_NAME} \
  --nodegroup-name ng-spot; echo "Nodegroup deleted" 
  
Nodegroup deleted
```