---
title: "Policy"
sidebar_position: 120
---

[Policies](https://kubernetes.io/docs/concepts/policy/) defines the cluster resource usages and restricts the deployment of _EKS Objects_ to meet the compliance and recommended best practices. Following are different types of policies that can applied at the cluster level.

- Limit Ranges
- Resource Quotas
- Process ID Limits And Reservations
- Node Resource Managers

A [LimitRange](https://kubernetes.io/docs/concepts/policy/limit-range/) is a policy to compel the resource allocations (limits and requests) specified to respective objects kind such as Pod, PersistentVolumeClaim in a namespace. _Resource allocation_ is all about making sure how much resources are needed and at the same time resources are not over consumed by the object. _Karpenter_ is kubernetes autoscaler helps to deploy right-sized resources based on the application demand. Refer [Karpenter](https://www.eksworkshop.com/beginner/085_scaling_karpenter/) workshop to configure _autoscaling_ in EKS Cluster.

[Resource Quotas](https://kubernetes.io/docs/concepts/policy/resource-quotas/), are hard limit defined at the namespace level and the objects like `pods`, `services`, compute resources like `cpu` and `memory` should be created with in the hard limit, else it will be rejected defined by a ResourceQuota object.

A [NetworkPolicy](https://kubernetes.io/docs/concepts/services-networking/network-policies/) establish the communication between source and the destinations, for example `ingress` and `egress` of the pod is controlled using network policies.

[Pod Disruption Budget](https://kubernetes.io/docs/tasks/run-application/configure-pdb/) in simple , is the way to mitigate disruptions that can happen to a pod voluntarily such as activities like deletion, updation of deployment, removal of pod etc. Read how _[disruptions](https://kubernetes.io/docs/concepts/workloads/pods/disruptions/)_ can happen to pods. 

Following screenshot displays list of _PodDistributionBudget's_ created and PDB can be created for each application.

![Insights](/img/resource-view/policy-poddisruption.jpg)

When you select the PDB _karpenter_, you can find the details such as the namespace to which pdb is assigned and the parameters that needs to be matched. In the below example, `max unavailable = 1` means maximum number of pods that can be unavailable is 1.

![Insights](/img/resource-view/policy-poddisruption-detail.jpg)