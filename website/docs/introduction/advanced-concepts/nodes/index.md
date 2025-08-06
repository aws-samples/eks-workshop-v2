---
title: Nodes
sidebar_position: 20
---

# Node Management

Kubernetes nodes are the worker machines that run your applications. Advanced node management allows you to control exactly where workloads run, handle node maintenance, and optimize resource utilization.

## Node Management Overview

| Concept | Purpose | Use Cases |
|---------|---------|-----------|
| **Node Selectors** | Simple node selection | Run on specific node types |
| **Node Affinity** | Advanced node selection | Complex placement rules |
| **Taints & Tolerations** | Node exclusion/inclusion | Dedicated nodes, maintenance |
| **Pod Affinity** | Pod co-location | Performance optimization |

## Why Control Pod Placement?

### Performance Optimization
- **GPU workloads** - Schedule on GPU-enabled nodes
- **Memory-intensive apps** - Place on high-memory nodes
- **Storage workloads** - Co-locate with fast storage

### Cost Optimization
- **Spot instances** - Use cheaper compute for fault-tolerant workloads
- **Reserved instances** - Maximize utilization of reserved capacity
- **Right-sizing** - Match workload requirements to node capabilities

### Compliance and Security
- **Dedicated tenancy** - Isolate sensitive workloads
- **Geographic requirements** - Data locality compliance
- **Hardware requirements** - Specific CPU architectures

### Operational Efficiency
- **Node maintenance** - Drain nodes for updates
- **Failure domains** - Spread across availability zones
- **Resource isolation** - Separate different workload types

## Node Information

### View Node Details
```bash
$ kubectl get nodes
NAME                                          STATUS   ROLES    AGE   VERSION
ip-10-42-10-104.us-west-2.compute.internal   Ready    <none>   1d    v1.28.1
ip-10-42-11-205.us-west-2.compute.internal   Ready    <none>   1d    v1.28.1
ip-10-42-12-156.us-west-2.compute.internal   Ready    <none>   1d    v1.28.1
```

### Node Labels
```bash
$ kubectl get nodes --show-labels
```

Common labels in EKS:
- `kubernetes.io/arch=amd64`
- `kubernetes.io/os=linux`
- `node.kubernetes.io/instance-type=m5.large`
- `topology.kubernetes.io/zone=us-west-2a`
- `eks.amazonaws.com/nodegroup=workers`

### Node Capacity and Allocatable
```bash
$ kubectl describe node <node-name>
```

Look for:
- **Capacity** - Total node resources
- **Allocatable** - Available for pods (after system reservations)
- **Allocated resources** - Currently used by pods

## Sections

- **[Selectors](./selectors)** - Control Pod placement with node selectors and affinity
- **[Taints & Tolerations](./taints-tolerations)** - Advanced scheduling with node exclusion

## Real-World Scenarios

### Scenario 1: GPU Workloads
You have ML workloads that need GPU nodes:

```yaml
nodeSelector:
  accelerator: nvidia-tesla-k80
```

### Scenario 2: Database on SSD Nodes
Database pods need fast storage:

```yaml
nodeSelector:
  storage-type: ssd
```

### Scenario 3: Multi-Zone Deployment
Spread application across availability zones:

```yaml
affinity:
  podAntiAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
    - labelSelector:
        matchLabels:
          app: web
      topologyKey: topology.kubernetes.io/zone
```

### Scenario 4: Dedicated Nodes
Some nodes reserved for specific applications:

```yaml
# Node has taint
kubectl taint nodes node1 dedicated=special-workload:NoSchedule

# Pod tolerates the taint
tolerations:
- key: dedicated
  operator: Equal
  value: special-workload
  effect: NoSchedule
```

## EKS-Specific Considerations

### Node Groups
EKS manages nodes through node groups with specific instance types:

```bash
$ kubectl get nodes -l eks.amazonaws.com/nodegroup=workers
```

### Availability Zones
EKS spreads nodes across AZs automatically:

```bash
$ kubectl get nodes -l topology.kubernetes.io/zone=us-west-2a
```

### Instance Types
Different instance types for different workloads:

```bash
$ kubectl get nodes -l node.kubernetes.io/instance-type=c5.xlarge
```

## Best Practices

### 1. Use Labels Consistently
```bash
# Label nodes by purpose
kubectl label nodes node1 workload-type=compute-intensive
kubectl label nodes node2 workload-type=memory-intensive
```

### 2. Plan for Failure Domains
```yaml
affinity:
  podAntiAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
    - weight: 100
      podAffinityTerm:
        labelSelector:
          matchLabels:
            app: web
        topologyKey: topology.kubernetes.io/zone
```

### 3. Set Resource Requests
```yaml
resources:
  requests:
    memory: "1Gi"
    cpu: "500m"
```

### 4. Use Node Affinity Over Node Selectors
Node affinity is more flexible than node selectors:

```yaml
affinity:
  nodeAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
    - weight: 1
      preference:
        matchExpressions:
        - key: instance-type
          operator: In
          values: ["c5.large", "c5.xlarge"]
```

### 5. Monitor Node Resources
```bash
$ kubectl top nodes
$ kubectl describe node <node-name>
```

## Getting Started

Let's start with [Selectors](./selectors) to learn the basics of controlling pod placement, then move on to advanced scheduling with [Taints & Tolerations](./taints-tolerations).