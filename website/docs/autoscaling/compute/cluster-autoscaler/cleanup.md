---
title: "Clean Up"
sidebar_position: 50
---

This module requires some manual cleanup due to the nature of the changes we made to our cluster. To make sure subsequent content runs correctly lets tidy up the cluster.

Make sure to disable the Cluster Autoscaler:

```bash wait=10
kubectl scale --replicas=0 -n workshop-system \
  deployment/cluster-autoscaler-aws-cluster-autoscaler
```