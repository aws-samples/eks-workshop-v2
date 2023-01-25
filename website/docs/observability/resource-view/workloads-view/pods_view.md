---
title: "Pods"
sidebar_position: 30
---

[Pods](https://kubernetes.io/docs/concepts/workloads/pods/) resource view displays all the pods which represent the smallest and simplest Kubernetes object.

![Insights](/img/resource-view/view-pods.jpg)

By default, all Kubernetes API resource types are shown, but you can filter by namespace or search for specific values to find what you’re looking for quickly. Below you will see the pods filtered by the namespace=<i>catalog</i>

![Insights](/img/resource-view/filter-pod.jpg)

The resources view for all Kubernetes API resource types, offers two views - structured view and raw view. The structured view provides a visual representation of the resource to help access the data for the resource. In this example (below), you can see a structured view for the catalog pod that breaks the pod information into Info, Containers, Labels and Annotations sections. It also details the associated replicaset, namespace and node.

![Insights](/img/resource-view/pod-detail-structured.jpg)

Raw view shows the complete JSON output from the Kubernetes API, which is useful for understanding the configuration and state of resource types that do not have structured view support in the Amazon EKS console. In the raw view example, we show the raw view for the catalog pod.

![Insights](/img/resource-view/pod-detail-raw.jpg)
