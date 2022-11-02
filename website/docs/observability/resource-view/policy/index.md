---
title: "Policy"
sidebar_position: 120
---

[Policies](https://kubernetes.io/docs/concepts/policy/)

A [LimitRange](https://kubernetes.io/docs/concepts/policy/limit-range/) is a policy to constrain the resource allocations (limits and requests) that you can specify for each applicable object kind (such as Pod or PersistentVolumeClaim) in a namespace.

A _LimitRange_ provides constraints that can:

- Enforce minimum and maximum compute resources usage per Pod or Container in a namespace.
- Enforce minimum and maximum storage request per PersistentVolumeClaim in a namespace.
- Enforce a ratio between request and limit for a resource in a namespace.
- Set default request/limit for compute resources in a namespace and automatically inject them to Containers at runtime.

[Resource Quotas](https://kubernetes.io/docs/concepts/policy/resource-quotas/), defined by a ResourceQuota object, provides constraints that limit aggregate resource consumption per namespace. It can limit the quantity of objects that can be created in a namespace by type, as well as the total amount of compute resources that may be consumed by resources in that namespace.

A [NetworkPolicy](https://kubernetes.io/docs/concepts/services-networking/network-policies/) is an application-centric construct which allow you to specify how a pod is allowed to communicate with various network "entities" (we use the word "entity" here to avoid overloading the more common terms such as "endpoints" and "services", which have specific Kubernetes connotations) over the network.

[Pod Disruption Budget](https://kubernetes.io/docs/tasks/run-application/configure-pdb/) allows an application owner to create an object for a replicated application, that ensures a certain number or percentage of Pods with an assigned label will not be voluntarily evicted at any point in time.

![Insights](/img/resource-view/policy-poddisruption.jpg)

![Insights](/img/resource-view/policy-poddisruption-detail.jpg)