---
title: "Resources"
sidebar_position: 10
---

To view the Kubernetes resources, click on the <i>Resources</i> tab. Drill down to the <i>Workload</i> section and you can view several of the Kubernetes API resource types that are part of workloads. Workloads encompass the running containers in your cluster, and include Pods, ReplicaSets, Deployments, and DaemonSets. These are fundamental building blocks for running containers with a cluster.

<strong>[Pods](https://kubernetes.io/docs/concepts/workloads/pods/)</strong> resource view displays all the pods which represent the smallest and simplest Kubernetes object.
By default, all Kubernetes API resource types are shown, but you can filter by namespace or search for specific values to find what you’re looking for quickly. Below you will see the pods filtered by the namespace=<i>catalog</i>

![Insights](/img/resource-view/filter-pod.jpg)

The resources view for all Kubernetes API resource types, offers two views - structured view and raw view. The structured view provides a visual representation of the resource to help access the data for the resource. Raw view shows the complete JSON output from the Kubernetes API, which is useful for understanding the configuration and state of resource types that do not have structured view support in the Amazon EKS console.

![Insights](/img/resource-view/pod-detail-structured.jpg)

A <strong>[ReplicaSet](https://kubernetes.io/docs/concepts/workloads/controllers/replicaset/)</strong> is a Kubernetes object that ensures a stable set of replica pods are running at all times. As such, it is often used to guarantee the availability of a specified number of identical pods. In this example (below), you can see 2 replicasets for namespace <i>orders</i>. The replicaset for orders-d6b4566fc defines the configuration for desired and current number of pods.

![Insights](/img/resource-view/replica-set.jpg)

Click on the replicaset <i>orders-d6b4566fc</i> and explore the configuration. You will see configurations under Info, Pods, labels and details of max and desired replicas.

A <strong>[Deployment](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)</strong> is a Kubernetes object that provides declarative updates to pods and replicaSets. It tells Kubernetes how to create or modify instances of pods. Deployments help to scale the number of replica pods and enable rollout or rollback a deployment version in a controlled manner. In this example (below), you can see 2 deployments for namespace <i>carts</i>.

![Insights](/img/resource-view/deploymentSet.jpg)

Click on the deployment <i>carts</i> and explore the configuration. You will see deployment strategy under Info, pod details under Pods, labels and deployment revision.

A <strong>[DaemonSet](https://kubernetes.io/docs/concepts/workloads/controllers/daemonset/)</strong> ensures that all (or some) Nodes run a copy of a pod. In the sample application we have DaemonSet running on each node as shown (below).

![Insights](/img/resource-view/daemonset.jpg)

Click on the daemonset <i>kube-proxy</i> and explore the configuration. You will see configurations under Info, pods running on each node, labels, and annotations.
