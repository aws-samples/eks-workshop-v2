---
title: Pods
sidebar_position: 20
---

# Pods

Pods are the fundamental building blocks of Kubernetes. They represent the smallest deployable units and typically contain a single container, though they can contain multiple containers that need to work closely together.

## Understanding Pods

### What is a Pod?
- A Pod wraps one or more containers
- Containers in a Pod share the same network (IP address and ports)
- Containers in a Pod share storage volumes
- Pods are ephemeral - they can be created, destroyed, and recreated

### Why Pods?
- **Shared resources** - Containers can communicate via localhost
- **Atomic deployment** - All containers start and stop together
- **Shared lifecycle** - If the Pod dies, all containers die
- **Co-location** - Containers are always scheduled on the same node

## Creating Your First Pod

Let's create a simple Pod running nginx:

```bash
$ cat << EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: my-first-pod
  labels:
    app: nginx
spec:
  containers:
  - name: nginx
    image: nginx:1.21
    ports:
    - containerPort: 80
EOF
```

Check that the Pod was created:

```bash
$ kubectl get pods
NAME           READY   STATUS    RESTARTS   AGE
my-first-pod   1/1     Running   0          30s
```

## Exploring Pod Details

Get detailed information about your Pod:

```bash
$ kubectl describe pod my-first-pod
```

This shows:
- Pod status and conditions
- Container information
- Events (what happened during Pod creation)
- Resource usage

## Interacting with Pods

### Viewing logs
```bash
$ kubectl logs my-first-pod
```

### Executing commands inside the Pod
```bash
$ kubectl exec -it my-first-pod -- /bin/bash
```

### Port forwarding to access the Pod
```bash
$ kubectl port-forward my-first-pod 8080:80
```

Now you can access nginx at http://localhost:8080

## Pod Lifecycle

Pods go through several phases:

1. **Pending** - Pod accepted but containers not yet created
2. **Running** - Pod bound to node and at least one container is running
3. **Succeeded** - All containers terminated successfully
4. **Failed** - All containers terminated, at least one failed
5. **Unknown** - Pod state cannot be determined

## Health Checks

Kubernetes can monitor container health using probes:

### Liveness Probe
Determines if a container is running. If it fails, Kubernetes restarts the container.

```yaml
livenessProbe:
  httpGet:
    path: /health
    port: 8080
  initialDelaySeconds: 30
  periodSeconds: 10
```

### Readiness Probe
Determines if a container is ready to serve traffic. If it fails, the Pod is removed from service endpoints.

```yaml
readinessProbe:
  httpGet:
    path: /ready
    port: 8080
  initialDelaySeconds: 5
  periodSeconds: 5
```

Let's create a Pod with health checks:

```bash
$ cat << EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: pod-with-probes
  labels:
    app: nginx-probes
spec:
  containers:
  - name: nginx
    image: nginx:1.21
    ports:
    - containerPort: 80
    livenessProbe:
      httpGet:
        path: /
        port: 80
      initialDelaySeconds: 30
      periodSeconds: 10
    readinessProbe:
      httpGet:
        path: /
        port: 80
      initialDelaySeconds: 5
      periodSeconds: 5
EOF
```

## Resource Management

Specify resource requests and limits:

```yaml
resources:
  requests:
    memory: "64Mi"
    cpu: "250m"
  limits:
    memory: "128Mi"
    cpu: "500m"
```

- **Requests** - Guaranteed resources for scheduling
- **Limits** - Maximum resources the container can use

## Multi-Container Pods

Sometimes you need multiple containers in a Pod:

```bash
$ cat << EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: multi-container-pod
spec:
  containers:
  - name: nginx
    image: nginx:1.21
    ports:
    - containerPort: 80
  - name: sidecar
    image: busybox
    command: ['sh', '-c', 'while true; do echo "Sidecar running"; sleep 30; done']
EOF
```

View logs from specific containers:

```bash
$ kubectl logs multi-container-pod -c nginx
$ kubectl logs multi-container-pod -c sidecar
```

## Troubleshooting Pods

### Common issues and solutions:

**Pod stuck in Pending**
```bash
$ kubectl describe pod <pod-name>
# Look for scheduling issues, resource constraints, or node problems
```

**Pod in CrashLoopBackOff**
```bash
$ kubectl logs <pod-name> --previous
# Check logs from the previous container instance
```

**Pod not ready**
```bash
$ kubectl describe pod <pod-name>
# Check readiness probe failures
```

## Best Practices

1. **Use labels** - Always add meaningful labels for organization
2. **Set resource limits** - Prevent containers from consuming too many resources
3. **Configure health checks** - Enable automatic recovery and traffic management
4. **Don't run Pods directly** - Use Deployments for production workloads
5. **Use namespaces** - Organize Pods logically

## Cleanup

Remove the Pods we created:

```bash
$ kubectl delete pod my-first-pod pod-with-probes multi-container-pod
```

## What's Next?

Now that you understand Pods, let's learn about [Deployments](../deployments) - the recommended way to manage Pods in production environments. Deployments provide scaling, rolling updates, and automatic Pod replacement.