---
title: "Installing CPA"
date: 2022-07-21T00:00:00-03:00
sidebar_position: 2
---

In this lab exercise, we'll be installing CPA using Kustomize manifests, the main part of which is the `Deployment` resource below:

```file
autoscaling/workloads/cpa/deployment.yaml
```

Let's apply this to our cluster:

```bash hook=cpa-install timeout=180
$ kubectl apply -k /workspace/modules/autoscaling/workloads/cpa
```

This will create a `Deployment` in the `kube-system` namespace which we can inspect:

```bash
$ kubectl get deployment dns-autoscaler -n other
NAME             READY   UP-TO-DATE   AVAILABLE   AGE
dns-autoscaler   1/1     1            1           10s
```

After CPA starts up it will automatically create a `ConfigMap` we can modify to adjust its configuration:

```bash
$ kubectl describe configmap dns-autoscaler -n kube-system
Name:         dns-autoscaler
Namespace:    other
Labels:       <none>
Annotations:  <none>

Data
====
linear:
----
{'coresPerReplica':2,'includeUnschedulableNodes':true,'nodesPerReplica':1,'preventSinglePointFailure':true,'min':1,'max':4}
Events:  <none>
```
