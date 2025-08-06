---
title: Taints & Tolerations
sidebar_position: 20
---

# Taints and Tolerations

Taints and tolerations work together to ensure pods are not scheduled onto inappropriate nodes. Taints are applied to nodes to repel pods, while tolerations are applied to pods to allow them to be scheduled on nodes with matching taints.

## Understanding Taints and Tolerations

### Taints
- **Applied to nodes** - Mark nodes as unsuitable for certain pods
- **Repel pods** - Prevent scheduling unless pod has matching toleration
- **Three effects** - NoSchedule, PreferNoSchedule, NoExecute

### Tolerations
- **Applied to pods** - Allow scheduling on tainted nodes
- **Match taints** - Must match key, value, and effect
- **Operators** - Equal (exact match) or Exists (key exists)

## Taint Effects

| Effect | Description | Impact |
|--------|-------------|---------|
| `NoSchedule` | New pods won't be scheduled | Existing pods remain |
| `PreferNoSchedule` | Avoid scheduling if possible | Soft constraint |
| `NoExecute` | Evict existing pods | Existing pods removed |

## Working with Taints

### Adding Taints to Nodes

```bash
# Basic taint
$ kubectl taint nodes node1 key1=value1:NoSchedule

# Taint without value
$ kubectl taint nodes node1 key1:NoSchedule

# Multiple effects
$ kubectl taint nodes node1 dedicated=gpu:NoSchedule
$ kubectl taint nodes node1 dedicated=gpu:NoExecute
```

### Viewing Node Taints

```bash
$ kubectl describe node node1
Name:               node1
...
Taints:             dedicated=gpu:NoSchedule
                    dedicated=gpu:NoExecute
```

### Removing Taints

```bash
# Remove specific taint
$ kubectl taint nodes node1 dedicated=gpu:NoSchedule-

# Remove all taints with key
$ kubectl taint nodes node1 dedicated-
```

## Working with Tolerations

### Basic Toleration

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: gpu-pod
spec:
  tolerations:
  - key: "dedicated"
    operator: "Equal"
    value: "gpu"
    effect: "NoSchedule"
  containers:
  - name: app
    image: nginx
```

### Toleration Operators

#### Equal Operator (Exact Match)
```yaml
tolerations:
- key: "dedicated"
  operator: "Equal"
  value: "gpu"
  effect: "NoSchedule"
```

#### Exists Operator (Key Exists)
```yaml
tolerations:
- key: "dedicated"
  operator: "Exists"
  effect: "NoSchedule"
```

#### Tolerate All Taints
```yaml
tolerations:
- operator: "Exists"
```

## Real-World Examples

### Example 1: Dedicated GPU Nodes

First, taint GPU nodes:

```bash
$ kubectl taint nodes gpu-node1 dedicated=gpu:NoSchedule
$ kubectl taint nodes gpu-node2 dedicated=gpu:NoSchedule
```

Create a GPU workload that can run on these nodes:

```bash
$ cat << EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ml-training
spec:
  replicas: 2
  selector:
    matchLabels:
      app: ml-training
  template:
    metadata:
      labels:
        app: ml-training
    spec:
      tolerations:
      - key: "dedicated"
        operator: "Equal"
        value: "gpu"
        effect: "NoSchedule"
      nodeSelector:
        accelerator: nvidia-tesla-k80
      containers:
      - name: trainer
        image: tensorflow/tensorflow:latest-gpu
        resources:
          limits:
            nvidia.com/gpu: 1
EOF
```

### Example 2: Node Maintenance

When performing maintenance, taint nodes to prevent new pods:

```bash
# Taint node for maintenance
$ kubectl taint nodes worker-1 maintenance=true:NoSchedule

# Drain existing pods (optional)
$ kubectl drain worker-1 --ignore-daemonsets --delete-emptydir-data
```

Create a maintenance pod that can run during maintenance:

```bash
$ cat << EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: maintenance-pod
spec:
  tolerations:
  - key: "maintenance"
    operator: "Equal"
    value: "true"
    effect: "NoSchedule"
  - key: "node.kubernetes.io/unschedulable"
    operator: "Exists"
    effect: "NoSchedule"
  containers:
  - name: maintenance
    image: busybox
    command: ['sh', '-c', 'echo "Running maintenance"; sleep 3600']
EOF
```

After maintenance, remove the taint:

```bash
$ kubectl taint nodes worker-1 maintenance=true:NoSchedule-
$ kubectl uncordon worker-1
```

### Example 3: NoExecute Effect

Taint a node with NoExecute to evict existing pods:

```bash
$ kubectl taint nodes worker-2 emergency=true:NoExecute
```

Pods without matching tolerations will be evicted immediately. Pods with tolerations can specify how long to tolerate:

```yaml
tolerations:
- key: "emergency"
  operator: "Equal"
  value: "true"
  effect: "NoExecute"
  tolerationSeconds: 300  # Tolerate for 5 minutes
```

## System Taints

Kubernetes automatically applies taints in certain situations:

### Node Conditions
```bash
# Node not ready
node.kubernetes.io/not-ready:NoExecute

# Node unreachable
node.kubernetes.io/unreachable:NoExecute

# Disk pressure
node.kubernetes.io/disk-pressure:NoSchedule

# Memory pressure
node.kubernetes.io/memory-pressure:NoSchedule

# PID pressure
node.kubernetes.io/pid-pressure:NoSchedule

# Network unavailable
node.kubernetes.io/network-unavailable:NoSchedule
```

### EKS-Specific Taints
```bash
# Spot instances
node.kubernetes.io/spot:NoSchedule

# Unschedulable nodes
node.kubernetes.io/unschedulable:NoSchedule
```

## DaemonSets and Tolerations

DaemonSets often need to run on all nodes, including tainted ones:

```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: log-collector
spec:
  selector:
    matchLabels:
      app: log-collector
  template:
    metadata:
      labels:
        app: log-collector
    spec:
      tolerations:
      # Tolerate all taints
      - operator: Exists
      containers:
      - name: collector
        image: fluentd
```

## Advanced Toleration Patterns

### Multiple Tolerations
```yaml
tolerations:
- key: "dedicated"
  operator: "Equal"
  value: "gpu"
  effect: "NoSchedule"
- key: "maintenance"
  operator: "Exists"
  effect: "NoSchedule"
- key: "node.kubernetes.io/not-ready"
  operator: "Exists"
  effect: "NoExecute"
  tolerationSeconds: 300
```

### Conditional Tolerations
Use init containers to add tolerations dynamically:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: conditional-pod
spec:
  initContainers:
  - name: check-node
    image: busybox
    command: ['sh', '-c', 'if [ "$NODE_TYPE" = "gpu" ]; then echo "gpu-toleration"; fi']
  containers:
  - name: app
    image: nginx
```

## Troubleshooting

### Pod Stuck in Pending
```bash
$ kubectl describe pod <pod-name>
```

Look for events like:
```
0/3 nodes are available: 3 node(s) had taints that the pod didn't tolerate.
```

### Check Node Taints
```bash
$ kubectl describe nodes | grep -A 5 Taints
```

### Verify Pod Tolerations
```bash
$ kubectl get pod <pod-name> -o yaml | grep -A 10 tolerations
```

### List Tainted Nodes
```bash
$ kubectl get nodes -o json | jq '.items[] | select(.spec.taints != null) | {name: .metadata.name, taints: .spec.taints}'
```

## Best Practices

### 1. Use Meaningful Taint Keys
```bash
# Good - descriptive keys
kubectl taint nodes node1 workload-type=database:NoSchedule
kubectl taint nodes node1 maintenance-window=true:NoSchedule

# Avoid - generic keys
kubectl taint nodes node1 special=true:NoSchedule
```

### 2. Document Taint Purposes
```bash
# Add annotations to explain taints
kubectl annotate node node1 taint.purpose="Dedicated for GPU workloads"
```

### 3. Use PreferNoSchedule for Soft Constraints
```bash
# Prefer not to schedule, but allow if necessary
kubectl taint nodes node1 preferred-workload=database:PreferNoSchedule
```

### 4. Set Appropriate Toleration Seconds
```yaml
tolerations:
- key: "node.kubernetes.io/not-ready"
  operator: "Exists"
  effect: "NoExecute"
  tolerationSeconds: 300  # 5 minutes grace period
```

### 5. Combine with Node Selectors
```yaml
spec:
  nodeSelector:
    workload-type: gpu
  tolerations:
  - key: "dedicated"
    operator: "Equal"
    value: "gpu"
    effect: "NoSchedule"
```

### 6. Use Taints for Node Lifecycle Management
```bash
# Before node maintenance
kubectl taint nodes node1 maintenance=scheduled:NoSchedule
kubectl drain node1

# After maintenance
kubectl taint nodes node1 maintenance=scheduled:NoSchedule-
kubectl uncordon node1
```

## Common Patterns

### Pattern 1: Dedicated Node Pool
```bash
# Taint all nodes in a pool
for node in $(kubectl get nodes -l nodepool=gpu -o name); do
  kubectl taint $node dedicated=gpu:NoSchedule
done
```

### Pattern 2: Gradual Node Drain
```bash
# First prevent new pods
kubectl taint nodes node1 draining=true:NoSchedule

# Then evict existing pods
kubectl taint nodes node1 draining=true:NoExecute
```

### Pattern 3: Emergency Eviction
```bash
# Immediately evict all pods
kubectl taint nodes node1 emergency=true:NoExecute
```

## Cleanup

Remove test taints and pods:

```bash
$ kubectl delete deployment ml-training
$ kubectl delete pod gpu-pod maintenance-pod
$ kubectl taint nodes node1 dedicated- maintenance- emergency- 2>/dev/null || true
```

## What's Next?

You've now learned about advanced node management with selectors, affinity, taints, and tolerations. Next, let's explore [RBAC](../rbac) to understand how to implement security and access controls in Kubernetes.