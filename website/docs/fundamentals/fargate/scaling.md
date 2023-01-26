---
title: Scaling the workload
sidebar_position: 30
---

Another benefit of Fargate is the simplified horizontal scaling model it offers. When using EC2 for compute, scaling Pods involves considering how not only the Pods will scale but also the underlying compute. Because Fargate abstracts away the underlying compute you only need to be concerned with scaling Pods themselves.

The examples we've looked at so far have only used a single Pod replica. What happens if we scale this out horizontally as we would typically expect in a real life scenario? Let's scale up the `checkout` service and find out:

```kustomization
fundamentals/fargate/scaling/deployment.yaml
Deployment/checkout
```

Apply the kustomization and wait for the rollout to complete:

```bash timeout=240
$ kubectl apply -k /workspace/modules/fundamentals/fargate/scaling
[...]
$ kubectl rollout status -n checkout deployment/checkout --timeout=200s
```

Once the rollout is complete we can check the number of Pods:

```bash
$ kubectl get pod -n checkout -l app.kubernetes.io/component=service
NAME                        READY   STATUS    RESTARTS   AGE
checkout-585c9b45c7-2c75m   1/1     Running   0          2m12s
checkout-585c9b45c7-c456l   1/1     Running   0          2m12s
checkout-585c9b45c7-xmx2t   1/1     Running   0          40m
```

Each of these Pods is scheduled on a separate Fargate instance. You can confirm this by following similar steps as previously and identifying the node of a given Pod.
