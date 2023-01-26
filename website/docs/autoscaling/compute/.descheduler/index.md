---
title: "Descheduler"
sidebar_position: 40
---

In this chapter we'll review how to useKubernetesdescheduler to evict pods based on specific strategies, so that the pods can be rescheduled on optimal worker nodes.

In Kubernetes, kube-scheduler is responsible for making the scheduling decisions to select optimal nodes for the newly created pods. It considers various factors like available resources, pod requirements, constraints, etc., 

As Kubernetes clusters are very dynamic and their state changes over time, there may be desire to move already running pods to some other nodes for various reasons:

* Nodes are under or over utilized.
* The original scheduling decision does not hold true any more, as taints or labels are added to or removed from nodes, pod/node affinity requirements are not satisfied any more, topology spread requirements are not met.
* Node failures requires pods to be moved.
* New nodes are added to clusters.
* Pods have been restarted too many times.
* Pod life time is expired.


Based on the configured policies, Descheduler finds pods that can be moved and evicts them. The scheduler will automatically kicks in and makes the new scheduling decision based on the current cluster state and pod requirements. 

# Policy and Strategies

Descheduler's policy is configurable and includes below strategies that can be enabled or disabled. By default, all strategies are enabled. In this chapter, we'll test `RemovePodsViolatingNodeTaints` and `PodLifeTime` strategies.

* RemoveDuplicates
* LowNodeUtilization
* HighNodeUtilization
* RemovePodsViolatingInterPodAntiAffinity
* RemovePodsViolatingNodeAffinity
* RemovePodsViolatingNodeTaints
* RemovePodsViolatingTopologySpreadConstraint
* RemovePodsHavingTooManyRestarts
* PodLifeTime
* RemoveFailedPods

The policy includes a common configuration that applies to all the strategies:

| Name | Default Value | Description |
|------|---------------|-------------|
| `nodeSelector` | `nil` | limiting the nodes which are processed |
| `evictLocalStoragePods` | `false` | allows eviction of pods with local storage |
| `evictSystemCriticalPods` | `false` | [Warning: Will evict Kubernetes system pods] allows eviction of pods with any priority, including system pods like kube-dns |
| `ignorePvcPods` | `false` | set whether PVC pods should be evicted or ignored |
| `maxNoOfPodsToEvictPerNode` | `nil` | maximum number of pods evicted from each node (summed through all strategies) |
| `maxNoOfPodsToEvictPerNamespace` | `nil` | maximum number of pods evicted from each namespace (summed through all strategies) |
| `evictFailedBarePods` | `false` | allow eviction of pods without owner references and in failed phase |

As part of the policy, the parameters associated with each strategy can be configured. Refer this [documentation](https://github.com/kubernetes-sigs/descheduler#policy-and-strategies) for details on available parameters.

The following diagram provides a visualization of most of the strategies to help categorize how strategies fit together.

TODO: Insert image
