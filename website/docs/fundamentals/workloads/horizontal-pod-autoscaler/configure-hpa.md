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
modules/autoscaling/workloads/hpa/deployment.yaml
Deployment/ui
```

Next, we need to create a `HorizontalPodAutoscaler` resource which defines the parameters HPA will use to determine how to scale our workload.

::yaml{file="manifests/modules/autoscaling/workloads/hpa/hpa.yaml" paths="spec.minReplicas,spec.maxReplicas,spec.scaleTargetRef,spec.targetCPUUtilizationPercentage"}

1. Always run at least 1 replica
2. Do not scale higher than 4 replicas
3. Instruct HPA to change the replica count on the `ui` Deployment
4. Set a target CPU utilization of 80%

Let's apply this configuration:

```bash
$ kubectl apply -k ~/environment/eks-workshop/modules/autoscaling/workloads/hpa
```
