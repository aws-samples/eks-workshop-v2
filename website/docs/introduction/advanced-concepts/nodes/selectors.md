---
title: Selectors
sidebar_position: 10
---

# Node Selectors and Affinity

Node selectors and node affinity allow you to control which nodes your pods are scheduled on. This is essential for performance optimization, compliance requirements, and resource management.

## Node Selectors

Node selectors are the simplest way to constrain pods to nodes with specific labels.

### Basic Node Selector

First, let's label a node:

```bash
$ kubectl label nodes <node-name> disktype=ssd
```

Then create a pod that requires SSD storage:

```bash
$ cat << EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: nginx-ssd
spec:
  containers:
  - name: nginx
    image: nginx
  nodeSelector:
    disktype: ssd
EOF
```

### Verify Placement
```bash
$ kubectl get pod nginx-ssd -o wide
NAME        READY   STATUS    RESTARTS   AGE   IP           NODE
nginx-ssd   1/1     Running   0          1m    10.244.1.4   node-with-ssd
```

### Multiple Node Selectors
You can specify multiple labels (AND logic):

```yaml
nodeSelector:
  disktype: ssd
  kubernetes.io/arch: amd64
```

## Node Affinity

Node affinity is more expressive than node selectors and supports:
- **Soft preferences** (preferred) vs **hard requirements** (required)
- **Multiple values** with operators like `In`, `NotIn`, `Exists`
- **Weight-based preferences**

### Required Node Affinity

```bash
$ cat << EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app-required
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web-app-required
  template:
    metadata:
      labels:
        app: web-app-required
    spec:
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: kubernetes.io/arch
                operator: In
                values: ["amd64"]
              - key: node.kubernetes.io/instance-type
                operator: In
                values: ["m5.large", "m5.xlarge", "c5.large"]
      containers:
      - name: web
        image: nginx
EOF
```

### Preferred Node Affinity

```bash
$ cat << EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app-preferred
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web-app-preferred
  template:
    metadata:
      labels:
        app: web-app-preferred
    spec:
      affinity:
        nodeAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 80
            preference:
              matchExpressions:
              - key: instance-type
                operator: In
                values: ["c5.large", "c5.xlarge"]
          - weight: 20
            preference:
              matchExpressions:
              - key: topology.kubernetes.io/zone
                operator: In
                values: ["us-west-2a"]
      containers:
      - name: web
        image: nginx
EOF
```

### Combined Required and Preferred

```yaml
affinity:
  nodeAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/arch
          operator: In
          values: ["amd64"]
    preferredDuringSchedulingIgnoredDuringExecution:
    - weight: 1
      preference:
        matchExpressions:
        - key: disktype
          operator: In
          values: ["ssd"]
```

## Node Affinity Operators

| Operator | Description | Example |
|----------|-------------|---------|
| `In` | Label value in list | `values: ["ssd", "nvme"]` |
| `NotIn` | Label value not in list | `values: ["hdd"]` |
| `Exists` | Label key exists | No values needed |
| `DoesNotExist` | Label key doesn't exist | No values needed |
| `Gt` | Numeric greater than | `values: ["10"]` |
| `Lt` | Numeric less than | `values: ["100"]` |

### Examples of Operators

```yaml
# Node must have SSD or NVMe storage
- key: disktype
  operator: In
  values: ["ssd", "nvme"]

# Node must NOT be spot instance
- key: node-lifecycle
  operator: NotIn
  values: ["spot"]

# Node must have GPU (any value)
- key: accelerator
  operator: Exists

# Node must NOT have the maintenance label
- key: maintenance
  operator: DoesNotExist
```

## Pod Affinity and Anti-Affinity

Control pod placement relative to other pods.

### Pod Affinity (Co-location)
Schedule pods together for performance:

```bash
$ cat << EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-with-cache
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
    spec:
      affinity:
        podAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
          - labelSelector:
              matchLabels:
                app: cache
            topologyKey: kubernetes.io/hostname
      containers:
      - name: web
        image: nginx
EOF
```

### Pod Anti-Affinity (Separation)
Spread pods across nodes/zones for high availability:

```bash
$ cat << EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-spread
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web-spread
  template:
    metadata:
      labels:
        app: web-spread
    spec:
      affinity:
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
          - labelSelector:
              matchLabels:
                app: web-spread
            topologyKey: kubernetes.io/hostname
      containers:
      - name: web
        image: nginx
EOF
```

This ensures no two pods run on the same node.

### Topology Keys

Common topology keys for spreading:

- `kubernetes.io/hostname` - Spread across nodes
- `topology.kubernetes.io/zone` - Spread across availability zones
- `topology.kubernetes.io/region` - Spread across regions
- `node.kubernetes.io/instance-type` - Spread across instance types

## Real-World Examples

### Database with SSD Storage
```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: database
spec:
  serviceName: database
  replicas: 3
  selector:
    matchLabels:
      app: database
  template:
    metadata:
      labels:
        app: database
    spec:
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: disktype
                operator: In
                values: ["ssd"]
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
          - labelSelector:
              matchLabels:
                app: database
            topologyKey: topology.kubernetes.io/zone
      containers:
      - name: database
        image: postgres:13
```

### ML Workload on GPU Nodes
```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: ml-training
spec:
  template:
    spec:
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: accelerator
                operator: Exists
              - key: node.kubernetes.io/instance-type
                operator: In
                values: ["p3.2xlarge", "p3.8xlarge"]
      containers:
      - name: trainer
        image: tensorflow/tensorflow:latest-gpu
        resources:
          limits:
            nvidia.com/gpu: 1
      restartPolicy: Never
```

### Web App with Cache Co-location
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web-app
  template:
    metadata:
      labels:
        app: web-app
    spec:
      affinity:
        podAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            podAffinityTerm:
              labelSelector:
                matchLabels:
                  app: redis-cache
              topologyKey: kubernetes.io/hostname
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            podAffinityTerm:
              labelSelector:
                matchLabels:
                  app: web-app
              topologyKey: kubernetes.io/hostname
      containers:
      - name: web
        image: nginx
```

## EKS-Specific Examples

### Spot Instance Workloads
```yaml
nodeSelector:
  node-lifecycle: spot
```

### Availability Zone Placement
```yaml
affinity:
  nodeAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      nodeSelectorTerms:
      - matchExpressions:
        - key: topology.kubernetes.io/zone
          operator: In
          values: ["us-west-2a", "us-west-2b"]
```

### Instance Type Selection
```yaml
affinity:
  nodeAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
    - weight: 100
      preference:
        matchExpressions:
        - key: node.kubernetes.io/instance-type
          operator: In
          values: ["c5.large", "c5.xlarge", "c5.2xlarge"]
```

## Troubleshooting

### Pod Stuck in Pending
```bash
$ kubectl describe pod <pod-name>
```

Look for events like:
- `0/3 nodes are available: 3 node(s) didn't match node selector`
- `0/3 nodes are available: 3 node(s) had taints that the pod didn't tolerate`

### Check Node Labels
```bash
$ kubectl get nodes --show-labels
$ kubectl describe node <node-name>
```

### Verify Affinity Rules
```bash
$ kubectl get pod <pod-name> -o yaml | grep -A 20 affinity
```

### Check Resource Availability
```bash
$ kubectl top nodes
$ kubectl describe node <node-name>
```

## Best Practices

### 1. Use Preferred Over Required When Possible
```yaml
# Better - allows scheduling even if preference can't be met
preferredDuringSchedulingIgnoredDuringExecution:
- weight: 100
  preference:
    matchExpressions:
    - key: disktype
      operator: In
      values: ["ssd"]
```

### 2. Combine Node and Pod Affinity
```yaml
affinity:
  nodeAffinity:
    # Ensure nodes have required capabilities
  podAntiAffinity:
    # Spread for high availability
```

### 3. Use Meaningful Weights
```yaml
preferredDuringSchedulingIgnoredDuringExecution:
- weight: 100  # Strong preference
  preference: # ...
- weight: 50   # Medium preference  
  preference: # ...
- weight: 10   # Weak preference
  preference: # ...
```

### 4. Label Nodes Consistently
```bash
# Use consistent labeling scheme
kubectl label nodes node1 workload-type=compute-intensive
kubectl label nodes node1 storage-type=ssd
kubectl label nodes node1 network-performance=high
```

### 5. Test Scheduling Rules
```bash
# Create test pods to verify rules work
kubectl run test-pod --image=busybox --dry-run=client -o yaml > test-pod.yaml
# Add affinity rules and apply
```

## Cleanup

Remove the test deployments:

```bash
$ kubectl delete deployment web-app-required web-app-preferred web-with-cache web-spread
$ kubectl delete pod nginx-ssd
```

## What's Next?

Now that you understand node selectors and affinity, let's learn about [Taints & Tolerations](./taints-tolerations) for more advanced scheduling scenarios like node maintenance and dedicated workloads.