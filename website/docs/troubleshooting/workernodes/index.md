---
title: "Worker Nodes"
sidebar_position: 50
description: "Bring worker nodes in an Amazon EKS Managed Nodegroup back to healthy state."
sidebar_custom_props: { "module": true }
---

In the following scenarios for worker nodes we will learn how to troubleshoot various AWS EKS worker node issues. The different scenarios will walk through what is causing nodes fail to join the cluster or stay in 'Not Ready' status, then fixing with a solution. Before you begin, if you want to learn more about how worker nodes are deployed as part of managed node groups see [Fundamentals module](/docs/fundamentals/compute/managed-node-groups).

:::tip Before you start
Prepare your environment for this section:

```bash timeout=600 wait=300
$ prepare-environment troubleshooting/workernodes
```

You can view the Terraform that applies these changes [here](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/troubleshooting/workernodes/.workshop/terraform).


:::
:::info

The preparation of the lab might take a couple of minutes and it will make the following changes to your lab environment: 
- Create a new managed node groups called new_nodegroup_1, new_nodegroup_2, new_nodegroup_3 with desired managed node group count to 1 
- Introduce a problem to the managed node groups which causes node join failure and ready issue 
- Deploy resource kubernetes resources (deployment, daemonset, namespace, configmaps, priority-class)

:::
