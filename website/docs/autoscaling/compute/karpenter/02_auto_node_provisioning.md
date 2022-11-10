---
title: "Automatic Node Provisioning"
sidebar_position: 40
---

With Karpenter now active, we can begin to explore how Karpenter provisions nodes. In this section we are going to scale up the `assets` service and watch Karpenter provision nodes in response.

```kustomization
autoscaling/compute/karpenter/scale/deployment.yaml
Deployment/assets
```

Let's apply this to our cluster:

```bash timeout=300 hook=karpenter-deployment
$ kubectl apply -k /workspace/modules/autoscaling/compute/karpenter/scale
```

Topics to cover here:

- Show Karpenter creates separate nodes not in node group (query by labels?)
- Show that Karpenter provisioned a right-sized node based on the replicas/memory requested by the Pod
