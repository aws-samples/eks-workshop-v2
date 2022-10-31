---
title: Clean Up
sidebar_position: 40
---

Finally lets reset the `deployment` assets back to its original configuration for the coming modules.

First Deploy the old version of the deployment , by running the below command :
```bash
$ kubectl apply -k /workspace/manifests/assets

namespace/assets unchanged
serviceaccount/assets unchanged
configmap/assets unchanged
service/assets unchanged
deployment.apps/assets configured
```
Delete the PVC we had created in a previous steps "efs-claim", by running the below command:

```bash
$ kubectl -n assets delete pvc efs-claim

persistentvolumeclaim "efs-claim" deleted
```
Delete storageclass object "efs-sc" we created in previous step, by running the below command:

```bash
$ kubectl delete sc efs-sc

storageclass.storage.k8s.io "efs-sc" deleted
```