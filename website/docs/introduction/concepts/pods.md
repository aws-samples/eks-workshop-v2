---
title: Pods
sidebar_position: 20
---

# Pods - The Smallest Deployable Units

**Pods** are the smallest deployable units in Kubernetes. They represent a group of one or more containers that share storage, network, and a specification for how to run.

## What Is a Pod?

A Pod:
- **Wraps one or more containers** (usually just one)
- **Shares a network** - all containers in a pod share the same IP address
- **Shares storage** - containers can share volumes
- **Lives and dies together** - if the pod is deleted, all containers are deleted
- **Is ephemeral** - pods can be created, destroyed, and recreated

## Pod Anatomy

Here's what a typical pod looks like in our retail store:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: catalog-pod
  namespace: catalog
  labels:
    app.kubernetes.io/name: catalog
    app.kubernetes.io/component: service
spec:
  containers:
  - name: catalog
    image: public.ecr.aws/aws-containers/retail-store-sample-catalog:1.2.1
    ports:
    - containerPort: 8080
      name: http
    env:
    - name: DB_HOST
      value: catalog-mysql
    resources:
      requests:
        cpu: 250m
        memory: 512Mi
      limits:
        cpu: 500m
        memory: 1Gi
```

## Key Pod Concepts

### 1. Container Specification
The `containers` section defines what runs in the pod:
- **Image** - Which container image to run
- **Ports** - Which ports the container exposes
- **Environment variables** - Configuration passed to the container
- **Resource requests/limits** - CPU and memory requirements

### 2. Shared Networking
All containers in a pod share:
- **IP address** - The pod gets one IP
- **Port space** - Containers can't use the same port
- **Localhost** - Containers can communicate via localhost

### 3. Shared Storage
Containers can share volumes:
```yaml
spec:
  containers:
  - name: app
    volumeMounts:
    - name: shared-data
      mountPath: /data
  - name: sidecar
    volumeMounts:
    - name: shared-data
      mountPath: /shared
  volumes:
  - name: shared-data
    emptyDir: {}
```

## Exploring Pods in Our Application

Let's examine the pods running our retail store:

```bash
# See all pods across all namespaces
$ kubectl get pods -A -l app.kubernetes.io/created-by=eks-workshop

# Focus on catalog pods
$ kubectl get pods -n catalog
```

You should see output like:
```
NAME                       READY   STATUS    RESTARTS   AGE
catalog-846479dcdd-fznf5   1/1     Running   0          5m
catalog-mysql-0            1/1     Running   0          5m
```

### Pod Details
Get detailed information about a pod:
```bash
$ kubectl describe pod -n catalog -l app.kubernetes.io/name=catalog
```

This shows:
- **Container specifications** - Image, ports, environment
- **Resource usage** - CPU and memory requests/limits
- **Events** - What happened during pod creation
- **Status** - Current state and health

### Pod Logs
View what's happening inside the pod:
```bash
# Get logs from the catalog pod
$ kubectl logs -n catalog -l app.kubernetes.io/name=catalog

# Follow logs in real-time
$ kubectl logs -n catalog -l app.kubernetes.io/name=catalog -f

# Get logs from a specific container (if pod has multiple)
$ kubectl logs -n catalog pod-name -c container-name
```

## Pod Lifecycle

Pods go through several phases:

### 1. Pending
The pod has been created but containers aren't running yet:
- Kubernetes is scheduling the pod to a node
- Container images are being downloaded
- Resources are being allocated

### 2. Running
At least one container is running:
- All containers have been created
- At least one is running, starting, or restarting

### 3. Succeeded
All containers have terminated successfully:
- Typically for batch jobs or one-time tasks
- Containers won't be restarted

### 4. Failed
All containers have terminated, and at least one failed:
- Container exited with non-zero status
- Container was terminated by the system

### 5. Unknown
Pod state cannot be determined:
- Usually due to communication issues with the node

## Health Checks

Pods can have health checks to ensure they're working properly:

### Liveness Probes
Check if the container is alive:
```yaml
livenessProbe:
  httpGet:
    path: /health
    port: 8080
  initialDelaySeconds: 30
  periodSeconds: 10
```

If this fails, Kubernetes restarts the container.

### Readiness Probes
Check if the container is ready to serve traffic:
```yaml
readinessProbe:
  httpGet:
    path: /ready
    port: 8080
  initialDelaySeconds: 5
  periodSeconds: 5
```

If this fails, the pod is removed from service endpoints.

### Startup Probes
Check if the container has started successfully:
```yaml
startupProbe:
  httpGet:
    path: /startup
    port: 8080
  failureThreshold: 30
  periodSeconds: 10
```

This is useful for slow-starting containers.

## Resource Management

Pods can specify resource requirements:

### Requests
Minimum resources guaranteed to the pod:
```yaml
resources:
  requests:
    cpu: 250m      # 0.25 CPU cores
    memory: 512Mi  # 512 megabytes
```

### Limits
Maximum resources the pod can use:
```yaml
resources:
  limits:
    cpu: 500m      # 0.5 CPU cores
    memory: 1Gi    # 1 gigabyte
```

## Working with Pods

### Creating Pods
```bash
# Imperative way
$ kubectl run my-pod --image=nginx --port=80

# Declarative way (recommended)
$ kubectl apply -f pod.yaml
```

### Executing Commands
Run commands inside a pod:
```bash
# Get a shell in the pod
$ kubectl exec -it -n catalog deployment/catalog -- /bin/bash

# Run a single command
$ kubectl exec -n catalog deployment/catalog -- curl localhost:8080/health
```

### Port Forwarding
Access a pod from your local machine:
```bash
# Forward local port 8080 to pod port 8080
$ kubectl port-forward -n catalog pod/catalog-pod 8080:8080
```

### Copying Files
Copy files to/from pods:
```bash
# Copy file to pod
$ kubectl cp local-file.txt catalog/catalog-pod:/tmp/file.txt

# Copy file from pod
$ kubectl cp catalog/catalog-pod:/tmp/file.txt local-file.txt
```

## Pod Patterns

### Single Container (Most Common)
One container per pod - our retail store uses this pattern:
```yaml
spec:
  containers:
  - name: catalog
    image: catalog:latest
```

### Sidecar Pattern
Helper container alongside main container:
```yaml
spec:
  containers:
  - name: app
    image: my-app:latest
  - name: logging-agent
    image: fluentd:latest
```

### Init Containers
Containers that run before the main containers:
```yaml
spec:
  initContainers:
  - name: setup
    image: busybox
    command: ['sh', '-c', 'setup database']
  containers:
  - name: app
    image: my-app:latest
```

## Troubleshooting Pods

### Common Issues

**Pod Stuck in Pending:**
```bash
$ kubectl describe pod -n catalog pod-name
# Look for scheduling issues, resource constraints
```

**Pod Crashing:**
```bash
$ kubectl logs -n catalog pod-name --previous
# Check logs from the previous container instance
```

**Pod Not Ready:**
```bash
$ kubectl describe pod -n catalog pod-name
# Check readiness probe failures
```

### Debug Commands
```bash
# Get pod events
$ kubectl get events -n catalog --sort-by='.lastTimestamp'

# Check resource usage
$ kubectl top pods -n catalog

# Get pod YAML
$ kubectl get pod -n catalog pod-name -o yaml
```

## Key Takeaways

- Pods are the smallest deployable units in Kubernetes
- Usually contain one container, but can contain multiple
- Share network and storage within the pod
- Are ephemeral - they come and go
- Health checks ensure pods are working correctly
- Resource requests and limits control resource usage

## Next Steps

Pods are typically not created directly. Instead, they're managed by higher-level controllers like [Deployments](./deployments), which handle scaling, updates, and pod lifecycle management.