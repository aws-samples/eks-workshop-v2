---
title: "Nodes"
sidebar_position: 30
---

Kubernetes runs your workload by placing containers into pods to run on [Nodes](https://kubernetes.io/docs/concepts/architecture/nodes/). A node may be a virtual or physical machine, depending on the cluster. The eks-workshop is running 3 nodes on which the workloads are deployed. Click on the Nodes drill down to list the nodes. 

![Insights](/img/resource-view/cluster-node.jpg)

If you click on any of the node names, you will find the Info section that has a lot of details of the node - OS, container runtime, instance type, EC2 instance and [Managed node group](https://docs.aws.amazon.com/eks/latest/userguide/managed-node-groups.html) (that make it easy to provision compute capacity for the cluster). The next section, Capacity allocation shows usage and reservation of various resources on EC2 worker nodes connected to the cluster.

![Insights](/img/resource-view/cluster-node-detail1.jpg)

The next section Pods, details all the pods provisioned on the node. In this example, there are 12 running pods on this node. 

![Insights](/img/resource-view/cluster-node-detail2.jpg)

The next section details any applicable [Taints](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/), labels and annotations.

![Insights](/img/resource-view/cluster-node-detail3.jpg)
