---
title: "Configure HPA"
sidebar_position: 10
---

Currently there are no resources in our cluster that enable horizontal pod autoscaling, which you can check with the following command:

```bash expectError=true
$ kubectl get hpa -A
No resources found
```

In this case we're going to use the `ui` service and scale it based on CPU usage. The first thing we'll do is update the `ui` Pod specification to specify CPU `request` and `limit` values.

```kustomization
autoscaling/workloads/hpa/deployment.yaml
Deployment/ui
```

Next, we need to create a `HorizontalPodAutoscaler` resource which defines the parameters HPA will use to determine how to scale our workload.

```file
autoscaling/workloads/hpa/hpa.yaml
```

Let's apply this configuration:

```bash
$ kubectl apply -k /workspace/modules/autoscaling/workloads/hpa
```
