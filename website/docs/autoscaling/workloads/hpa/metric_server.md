---
title: "Metric server"
sidebar_position: 5
---

The Kubernetes Metrics Server is an aggregator of resource usage data in your cluster, and it is not deployed by default in Amazon EKS clusters. For more information, see [Kubernetes Metrics Server](https://github.com/kubernetes-sigs/metrics-server) on GitHub. The Metrics Server is commonly used by other Kubernetes add-ons, such as the Horizontal Pod Autoscaler or the Kubernetes Dashboard. For more information, see [Resource metrics pipeline](https://kubernetes.io/docs/tasks/debug/debug-cluster/resource-metrics-pipeline/) in the Kubernetes documentation. In this lab exercise, we'll deploy the Kubernetes Metrics Server on our Amazon EKS cluster.

The Metric Server has been set up in advance in our cluster for this workshop:

```bash
$ kubectl -n kube-system get pod -l app.kubernetes.io/name=metrics-server
```

To get a view of the metrics that HPA will use to drive its scaling behavior, use the `kubectl top` command. For example, this command will show the resource utilization of the nodes in our cluster:

```bash
$ kubectl top node
```

You can also get resource utilization of pods, for example:

```bash
$ kubectl top pod -l app.kubernetes.io/created-by=eks-workshop -A
```

As we see the HPA scale pods you can continue to use these queries to understand what is happening.
