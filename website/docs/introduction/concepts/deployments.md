---
title: Deployments
sidebar_position: 30
---

# Deployments - Managing Pod Lifecycles

**Deployments** are Kubernetes controllers that manage the lifecycle of pods. They handle scaling, rolling updates, and ensure your desired number of pods are always running.

## What Is a Deployment?

A Deployment:
- **Manages ReplicaSets** - which in turn manage pods
- **Ensures desired state** - keeps the specified number of pods running
- **Handles rolling updates** - updates pods without downtime
- **Provides rollback capability** - can revert to previous versions
- **Scales horizontally** - can increase or decrease pod count

## Deployment Anatomy

Here's the catalog deployment from our retail store:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: catalog
  namespace: catalog
  labels:
    app.kubernetes.io/name: catalog
spec:
  replicas: 1                    # How many pods to run
  selector:
    matchLabels:                 # How to find pods to manage
      app.kubernetes.io/name: catalog
      app.kubernetes.io/component: service
  template:                      # Pod template
    metadata:
      labels:                    # Labels applied to pods
        app.kubernetes.io/name: catalog
        app.kubernetes.io/component: service
    spec:
      containers:
      - name: catalog
        image: public.ecr.aws/aws-containers/retail-store-sample-catalog:1.2.1
        ports:
        - containerPort: 8080
        resources:
          requests:
            cpu: 250m
            memory: 512Mi
          limits:
            cpu: 500m
            memory: 1Gi
```

## Key Deployment Concepts

### 1. Replicas
The `replicas` field specifies how many identical pods should be running:
```yaml
spec:
  replicas: 3  # Run 3 identical pods
```

### 2. Selector
The `selector` tells the deployment which pods it manages:
```yaml
spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: catalog
```

This must match the labels in the pod template.

### 3. Pod Template
The `template` section defines what each pod should look like:
```yaml
spec:
  template:
    metadata:
      labels:
        app.kubernetes.io/name: catalog
    spec:
      containers:
      - name: catalog
        image: catalog:1.2.1
```

## Exploring Deployments in Our Application

Let's examine the deployments in our retail store:

```bash
# See all deployments
$ kubectl get deployments -A -l app.kubernetes.io/created-by=eks-workshop

# Focus on catalog deployment
$ kubectl get deployment -n catalog
```

You should see:
```
NAME      READY   UP-TO-DATE   AVAILABLE   AGE
catalog   1/1     1            1           10m
```

- **READY** - How many pods are ready vs desired
- **UP-TO-DATE** - How many pods have the latest template
- **AVAILABLE** - How many pods are available to serve traffic

### Deployment Details
Get detailed information:
```bash
$ kubectl describe deployment -n catalog catalog
```

This shows:
- **Replica status** - Current vs desired
- **Pod template** - Container specifications
- **Events** - Recent deployment activities
- **Conditions** - Current deployment state

## Scaling Deployments

One of the key benefits of deployments is easy scaling:

### Manual Scaling
```bash
# Scale to 3 replicas
$ kubectl scale deployment -n catalog catalog --replicas=3

# Verify scaling
$ kubectl get pods -n catalog
```

You should see 3 catalog pods running.

### Declarative Scaling
Update the YAML and apply:
```yaml
spec:
  replicas: 5
```

```bash
$ kubectl apply -f deployment.yaml
```

### Scaling Back
```bash
# Scale back to 1 replica
$ kubectl scale deployment -n catalog catalog --replicas=1
```

## Rolling Updates

Deployments handle updates without downtime:

### Update Strategy
```yaml
spec:
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1      # Max pods that can be unavailable
      maxSurge: 1           # Max extra pods during update
```

### Performing Updates
```bash
# Update the image
$ kubectl set image deployment/catalog -n catalog catalog=catalog:1.3.0

# Watch the rollout
$ kubectl rollout status deployment/catalog -n catalog
```

### Rollout History
```bash
# See rollout history
$ kubectl rollout history deployment/catalog -n catalog

# See specific revision
$ kubectl rollout history deployment/catalog -n catalog --revision=2
```

### Rolling Back
```bash
# Rollback to previous version
$ kubectl rollout undo deployment/catalog -n catalog

# Rollback to specific revision
$ kubectl rollout undo deployment/catalog -n catalog --to-revision=1
```

## Deployment Strategies

### Rolling Update (Default)
Gradually replaces old pods with new ones:
- **Zero downtime** - service remains available
- **Gradual rollout** - can catch issues early
- **Resource efficient** - doesn't need double resources

### Recreate
Kills all old pods before creating new ones:
```yaml
spec:
  strategy:
    type: Recreate
```
- **Downtime** - service unavailable during update
- **Fast** - quick transition
- **Resource efficient** - no extra pods needed

## Health Checks and Deployments

Deployments work with pod health checks:

### Readiness Gates
Only count pods as ready when they pass readiness checks:
```yaml
spec:
  template:
    spec:
      containers:
      - name: catalog
        readinessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 10
          periodSeconds: 5
```

### Deployment Conditions
Deployments have their own conditions:
- **Progressing** - Deployment is making progress
- **Available** - Minimum replicas are available
- **ReplicaFailure** - Deployment can't create replicas

## Working with Deployments

### Creating Deployments
```bash
# Imperative way
$ kubectl create deployment my-app --image=nginx --replicas=3

# Declarative way (recommended)
$ kubectl apply -f deployment.yaml
```

### Updating Deployments
```bash
# Update image
$ kubectl set image deployment/my-app container=nginx:1.20

# Update resources
$ kubectl patch deployment my-app -p '{"spec":{"template":{"spec":{"containers":[{"name":"nginx","resources":{"requests":{"cpu":"200m"}}}]}}}}'

# Edit directly
$ kubectl edit deployment my-app
```

### Monitoring Deployments
```bash
# Watch deployment status
$ kubectl get deployment my-app -w

# Check rollout status
$ kubectl rollout status deployment/my-app

# Get deployment events
$ kubectl describe deployment my-app
```

## Deployment vs ReplicaSet vs Pod

Understanding the hierarchy:

### Pod
- Single instance of your application
- Ephemeral and replaceable
- Directly managed by ReplicaSet

### ReplicaSet
- Ensures a specific number of pods are running
- Manages pod creation and deletion
- Usually managed by Deployment

### Deployment
- Manages ReplicaSets
- Handles rolling updates and rollbacks
- Provides declarative updates

```
Deployment → ReplicaSet → Pod
```

## Best Practices

### 1. Always Use Deployments
Don't create pods directly - use deployments for:
- **Scaling** - Easy horizontal scaling
- **Updates** - Rolling updates without downtime
- **Recovery** - Automatic pod replacement

### 2. Set Resource Limits
Always specify resource requests and limits:
```yaml
resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 500m
    memory: 512Mi
```

### 3. Use Health Checks
Implement readiness and liveness probes:
```yaml
livenessProbe:
  httpGet:
    path: /health
    port: 8080
readinessProbe:
  httpGet:
    path: /ready
    port: 8080
```

### 4. Label Everything
Use consistent labels for organization:
```yaml
metadata:
  labels:
    app.kubernetes.io/name: catalog
    app.kubernetes.io/version: "1.2.1"
    app.kubernetes.io/component: service
```

### 5. Configure Update Strategy
Choose appropriate update strategy:
```yaml
spec:
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 25%
      maxSurge: 25%
```

## Troubleshooting Deployments

### Common Issues

**Deployment Not Progressing:**
```bash
$ kubectl describe deployment my-app
# Check for resource constraints, image pull errors
```

**Pods Not Ready:**
```bash
$ kubectl get pods -l app=my-app
$ kubectl describe pod pod-name
# Check readiness probe failures
```

**Rollout Stuck:**
```bash
$ kubectl rollout status deployment/my-app --timeout=300s
# Check if rollout is progressing
```

### Debug Commands
```bash
# Get deployment status
$ kubectl get deployment my-app -o wide

# Check replica sets
$ kubectl get replicaset -l app=my-app

# View deployment events
$ kubectl get events --field-selector involvedObject.name=my-app
```

## Key Takeaways

- Deployments manage the lifecycle of pods
- They provide scaling, rolling updates, and rollback capabilities
- Use the pod template to define what each pod should look like
- Rolling updates enable zero-downtime deployments
- Always use deployments instead of creating pods directly

## Next Steps

Deployments create and manage pods, but how do other components access these pods? That's where [Services](./services) come in - they provide stable network endpoints for accessing your deployments.