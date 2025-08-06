---
title: Deployments
sidebar_position: 30
---

# Deployments

While Pods are the basic unit of deployment, you rarely create them directly in production. Instead, you use Deployments, which provide declarative updates, scaling, and management for Pods.

## Why Use Deployments?

Deployments solve several problems with managing Pods directly:

- **Scaling** - Easily increase or decrease the number of Pod replicas
- **Rolling updates** - Update applications without downtime
- **Rollbacks** - Quickly revert to previous versions
- **Self-healing** - Automatically replace failed Pods
- **Declarative management** - Describe desired state, let Kubernetes handle the details

## Creating Your First Deployment

Let's create a Deployment that manages nginx Pods:

```bash
$ cat << EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  labels:
    app: nginx
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
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

## Understanding the Deployment Structure

Let's break down the key parts:

- **replicas: 3** - Run 3 copies of the Pod
- **selector** - How the Deployment finds its Pods
- **template** - The Pod specification to create

Check your Deployment:

```bash
$ kubectl get deployments
NAME               READY   UP-TO-DATE   AVAILABLE   AGE
nginx-deployment   3/3     3            3           1m

$ kubectl get pods -l app=nginx
NAME                                READY   STATUS    RESTARTS   AGE
nginx-deployment-7d8b49557f-4x2k9   1/1     Running   0          1m
nginx-deployment-7d8b49557f-7j8m2   1/1     Running   0          1m
nginx-deployment-7d8b49557f-k9n4l   1/1     Running   0          1m
```

## Scaling Applications

### Scale up
```bash
$ kubectl scale deployment nginx-deployment --replicas=5
deployment.apps/nginx-deployment scaled

$ kubectl get pods -l app=nginx
NAME                                READY   STATUS    RESTARTS   AGE
nginx-deployment-7d8b49557f-4x2k9   1/1     Running   0          3m
nginx-deployment-7d8b49557f-7j8m2   1/1     Running   0          3m
nginx-deployment-7d8b49557f-k9n4l   1/1     Running   0          3m
nginx-deployment-7d8b49557f-m8x7q   1/1     Running   0          30s
nginx-deployment-7d8b49557f-p2r5t   1/1     Running   0          30s
```

### Scale down
```bash
$ kubectl scale deployment nginx-deployment --replicas=2
```

### Declarative scaling
You can also edit the Deployment directly:

```bash
$ kubectl edit deployment nginx-deployment
# Change replicas: 2 to replicas: 4, save and exit
```

## Rolling Updates

One of Deployment's most powerful features is rolling updates - updating your application without downtime.

### Update the image
```bash
$ kubectl set image deployment/nginx-deployment nginx=nginx:1.22
deployment.apps/nginx-deployment image updated
```

Watch the rollout:
```bash
$ kubectl rollout status deployment/nginx-deployment
Waiting for deployment "nginx-deployment" rollout to finish: 1 out of 2 new replicas have been updated...
Waiting for deployment "nginx-deployment" rollout to finish: 1 out of 2 new replicas have been updated...
deployment "nginx-deployment" successfully rolled out
```

### View rollout history
```bash
$ kubectl rollout history deployment/nginx-deployment
deployment.apps/nginx-deployment 
REVISION  CHANGE-CAUSE
1         <none>
2         <none>
```

## Rollback Strategy

If something goes wrong, you can quickly rollback:

```bash
$ kubectl rollout undo deployment/nginx-deployment
deployment.apps/nginx-deployment rolled back

# Or rollback to a specific revision
$ kubectl rollout undo deployment/nginx-deployment --to-revision=1
```

## Deployment Strategies

### Rolling Update (Default)
- Gradually replaces old Pods with new ones
- Ensures some Pods are always available
- Configurable with `maxUnavailable` and `maxSurge`

```yaml
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxUnavailable: 1
    maxSurge: 1
```

### Recreate
- Kills all existing Pods before creating new ones
- Causes downtime but ensures no mixed versions

```yaml
strategy:
  type: Recreate
```

## Advanced Deployment Configuration

### Resource Management
```yaml
spec:
  template:
    spec:
      containers:
      - name: nginx
        image: nginx:1.21
        resources:
          requests:
            memory: "64Mi"
            cpu: "250m"
          limits:
            memory: "128Mi"
            cpu: "500m"
```

### Health Checks
```yaml
spec:
  template:
    spec:
      containers:
      - name: nginx
        image: nginx:1.21
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
```

### Environment Variables
```yaml
spec:
  template:
    spec:
      containers:
      - name: nginx
        image: nginx:1.21
        env:
        - name: ENV_VAR_NAME
          value: "env_var_value"
```

## Monitoring Deployments

### Check Deployment status
```bash
$ kubectl get deployment nginx-deployment -o wide
```

### View detailed information
```bash
$ kubectl describe deployment nginx-deployment
```

### Monitor Pod status
```bash
$ kubectl get pods -l app=nginx -w
# Use -w to watch for changes
```

## Troubleshooting Deployments

### Common issues:

**Deployment not progressing**
```bash
$ kubectl describe deployment nginx-deployment
# Look for events and conditions
```

**Pods not starting**
```bash
$ kubectl get pods -l app=nginx
$ kubectl describe pod <pod-name>
$ kubectl logs <pod-name>
```

**Image pull errors**
```bash
$ kubectl describe pod <pod-name>
# Look for "Failed to pull image" events
```

## ReplicaSets

Deployments actually create ReplicaSets, which manage the Pods:

```bash
$ kubectl get replicasets -l app=nginx
NAME                          DESIRED   CURRENT   READY   AGE
nginx-deployment-7d8b49557f   2         2         2       10m
```

- Deployment manages ReplicaSets
- ReplicaSets manage Pods
- This enables rolling updates and rollbacks

## Best Practices

1. **Always use Deployments** - Don't create Pods directly in production
2. **Set resource limits** - Prevent resource starvation
3. **Configure health checks** - Enable automatic recovery
4. **Use meaningful labels** - Organize and select resources
5. **Version your images** - Avoid `latest` tag in production
6. **Test rollouts** - Verify updates work before full deployment
7. **Monitor rollouts** - Watch deployment progress

## Cleanup

Remove the Deployment:

```bash
$ kubectl delete deployment nginx-deployment
```

This will also delete all associated ReplicaSets and Pods.

## What's Next?

Now that you understand how to manage application lifecycle with Deployments, let's learn about [Services](../services) - how to expose your applications and enable communication between components.