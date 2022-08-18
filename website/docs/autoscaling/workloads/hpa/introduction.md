---
title: "Configure HPA"
sidebar_position: 10
---

Run the following command to setup the EKS cluster for this module:

```bash timeout=300 wait=30
reset-environment
```

Currently there are no `HorizontalPodAutoscaler` resources in our cluster, which you can check with the following command:

```bash expectError=true
kubectl get hpa -A
No resources found
```

In this case we're going to use the `ui` service and scale it based on CPU usage. The first thing we'll do is update the `ui` Pod specification to specify CPU `request` and `limit` values.

```kustomization
autoscaling/workloads/hpa/deployment.yaml
Deployment/ui
```

Next we need to create a `HorizontalPodAutoscaler` resource which defines the parameters HPA will use to determine how to scale our workload.

```file
autoscaling/workloads/hpa/hpa.yaml
```

Lets apply this configuration:

```bash
kubectl apply -k /workspace/modules/autoscaling/workloads/hpa
```