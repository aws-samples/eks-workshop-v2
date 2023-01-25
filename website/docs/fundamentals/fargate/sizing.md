---
title: Resource allocation
sidebar_position: 20
---

The primary dimensions of [Fargate pricing](https://aws.amazon.com/fargate/pricing/) is based on CPU and memory, and the amount of resources allocated to a Fargate instance depend on the resource requests specified by the Pod. There is a [documented set](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/AWS_Fargate.html#fargate-tasks-size) of valid CPU and memory combinations for Fargate that should be considered when assessing if a workload is suitable for Fargate.

We can confirm what resources were provisioned for our Pod from the previous deployment by inspecting its annotations:

```bash
$ kubectl get pod -n checkout -l app.kubernetes.io/component=service -o json | jq -r '.items[0].metadata.annotations'
{
  "CapacityProvisioned": "0.25vCPU 0.5GB",
  "Logging": "LoggingDisabled: LOGGING_CONFIGMAP_NOT_FOUND",
  "kubernetes.io/psp": "eks.privileged",
  "prometheus.io/path": "/metrics",
  "prometheus.io/port": "8080",
  "prometheus.io/scrape": "true"
}
```

In this example (above), we can see that the `CapacityProvisioned` annotation shows that we were allocated 0.25 vCPU and 0.5 GB of memory, which is the minimum Fargate instance size. But what if our Pod needs more resources? Luckily Fargate provides a variety of options depending on the resource requests that we can try out.

In the next example we'll increase the amount of resources the `checkout` component is requesting and see how the Fargate scheduler adapts. The kustomization we're going to apply increases the resources requested to 1 vCPU and 2.5G of memory:

```kustomization
fundamentals/fargate/sizing/deployment.yaml
Deployment/checkout
```

Apply the kustomization and wait for the rollout to complete:

```bash timeout=220
$ kubectl apply -k /workspace/modules/fundamentals/fargate/sizing
[...]
$ kubectl rollout status -n checkout deployment/checkout --timeout=200s
```

Now, let's check again the resource allocated by Fargate. Based on the changes outlined above, what do you expect to see?

```bash
$ kubectl get pod -n checkout -l app.kubernetes.io/component=service -o json | jq -r '.items[0].metadata.annotations'
{
  "CapacityProvisioned": "1vCPU 3GB",
  "Logging": "LoggingDisabled: LOGGING_CONFIGMAP_NOT_FOUND",
  "kubernetes.io/psp": "eks.privileged",
  "prometheus.io/path": "/metrics",
  "prometheus.io/port": "8080",
  "prometheus.io/scrape": "true"
}
```

The resources requested by the Pod have been rounded up to the nearest Fargate configuration outlined in the valid set of combinations above.
