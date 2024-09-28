---
title: "Policy"
sidebar_position: 60
---

[Policies](https://kubernetes.io/docs/concepts/policy/) defines the cluster resource usages and restricts the deployment of _Kubernetes Objects_ to meet recommended best practices. Following are different types of policies that can be viewed at the cluster level in the **_Resource Types_** - **_Policy_** section

- Limit Ranges
- Resource Quotas
- Network Policies
- Pod Disruption Budgets
- Pod Security Policies

A [LimitRange](https://kubernetes.io/docs/concepts/policy/limit-range/) is a policy to limit resource allocations (limits and requests) specified to respective objects kind such as Pod, PersistentVolumeClaim in a namespace. _Resource allocation_ is used to specify resources that are needed and at the same time ensure resources are not over consumed by the object. _Karpenter_ is a Kubernetes auto-scaler that helps to deploy right-sized resources based on the application demand. Refer [Karpenter](../../../autoscaling/compute/karpenter/index.md) section to configure _autoscaling_ in EKS Cluster.

[Resource Quotas](https://kubernetes.io/docs/concepts/policy/resource-quotas/), are hard limit defined at the namespace level and the objects like `pods`, `services`, compute resources like `cpu` and `memory` should be created with in the hard limit, else it will be rejected defined by a ResourceQuota object.

A [NetworkPolicy](https://kubernetes.io/docs/concepts/services-networking/network-policies/) establish the communication between source and the destinations, for example `ingress` and `egress` of the pod is controlled using network policies.

[Pod Disruption Budget](https://kubernetes.io/docs/tasks/run-application/configure-pdb/) is a way to mitigate disruptions that can happen to a pod such as deletion, updates to deployments, removal of pod etc. More information on the types of _[disruptions](https://kubernetes.io/docs/concepts/workloads/pods/disruptions/)_ that can happen to pods.

The following screenshot displays a list of the _PodDistributionBudgets_ by namespace.

![Insights](/img/resource-view/policy-poddisruption.jpg)

Let's examine the _Pod Disruption Budget_ for _karpenter_, you can see the details of this resource such as the namespace and the parameters that needs to be matched for this _Pod Disruption Budget_. In the below screenshot, `max unavailable = 1` is set, which means the maximum number of _karpenter_ pods that can be unavailable is 1.

![Insights](/img/resource-view/policy-poddisruption-detail.jpg)
