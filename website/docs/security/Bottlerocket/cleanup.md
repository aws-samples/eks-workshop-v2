---
title: "CLEANUP"
sidebar_position: 50
---

```
1. kubectl delete carts application pod

2. kubectl delete namespace bottlerocket-nginx

3. Remove the following #bottlerocket json section in managed_node_groups from the file “/eks-workshop-v2/terraform/modules/cluster/eks.tf”:
```