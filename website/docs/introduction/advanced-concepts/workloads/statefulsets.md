---
title: StatefulSets
sidebar_position: 10
---

# StatefulSets

StatefulSets manage stateful applications that need persistent storage, stable network identities, and ordered deployment. Unlike Deployments, StatefulSets provide guarantees about the ordering and uniqueness of pods.

## StatefulSets vs Deployments

| Feature | Deployment | StatefulSet |
|---------|------------|-------------|
| **Pod Identity** | Random names | Predictable names (web-0, web-1) |
| **Network Identity** | Dynamic IPs | Stable hostnames |
| **Storage** | Shared or ephemeral | Persistent per pod |
| **Scaling** | Parallel | Sequential (ordered) |
| **Updates** | Rolling (parallel) | Rolling (ordered) |

## When to Use StatefulSets

### Perfect for:
- **Databases** - MySQL, PostgreSQL, MongoDB
- **Distributed systems** - Kafka, Elasticsearch, Zookeeper
- **Applications requiring** - Persistent data, stable network identity

### Not suitable for:
- **Stateless applications** - Use Deployments instead
- **Simple batch jobs** - Use Jobs instead
- **System services** - Use DaemonSets instead

## StatefulSet Components

### Pod Identity
StatefulSets create pods with predictable names:
- `web-0`, `web-1`, `web-2` (not random like `web-abc123-xyz`)
- Names are stable across restarts and rescheduling

### Headless Service
StatefulSets require a headless service for stable network identity:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: web-service
spec:
  clusterIP: None  # This makes it headless
  selector:
    app: web
  ports:
  - port: 80
```

### Persistent Volume Claims
Each pod gets its own persistent storage:

```yaml
volumeClaimTemplates:
- metadata:
    name: data
  spec:
    accessModes: ["ReadWriteOnce"]
    resources:
      requests:
        storage: 1Gi
```

## Creating Your First StatefulSet

Let's create a simple StatefulSet with nginx:

```bash
$ cat << EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: nginx-headless
spec:
  clusterIP: None
  selector:
    app: nginx-stateful
  ports:
  - port: 80
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: nginx-stateful
spec:
  serviceName: nginx-headless
  replicas: 3
  selector:
    matchLabels:
      app: nginx-stateful
  template:
    metadata:
      labels:
        app: nginx-stateful
    spec:
      containers:
      - name: nginx
        image: nginx:1.21
        ports:
        - containerPort: 80
        volumeMounts:
        - name: data
          mountPath: /usr/share/nginx/html
  volumeClaimTemplates:
  - metadata:
      name: data
    spec:
      accessModes: ["ReadWriteOnce"]
      resources:
        requests:
          storage: 1Gi
EOF
```

## Observing StatefulSet Behavior

### Ordered Creation
Watch pods being created sequentially:

```bash
$ kubectl get pods -l app=nginx-stateful -w
NAME              READY   STATUS    RESTARTS   AGE
nginx-stateful-0  1/1     Running   0          30s
nginx-stateful-1  0/1     Pending   0          0s
nginx-stateful-1  0/1     ContainerCreating   0          0s
nginx-stateful-1  1/1     Running             0          10s
nginx-stateful-2  0/1     Pending             0          0s
```

Notice how `nginx-stateful-1` only starts after `nginx-stateful-0` is ready.

### Stable Network Identity
Each pod gets a stable DNS name:

```bash
$ kubectl run test-pod --image=busybox --rm -it --restart=Never -- sh
# Inside the pod:
/ # nslookup nginx-stateful-0.nginx-headless.default.svc.cluster.local
/ # nslookup nginx-stateful-1.nginx-headless.default.svc.cluster.local
/ # nslookup nginx-stateful-2.nginx-headless.default.svc.cluster.local
```

### Persistent Storage
Each pod has its own persistent volume:

```bash
$ kubectl get pvc
NAME                     STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
data-nginx-stateful-0    Bound    pvc-abc123...                             1Gi        RWO            gp2            5m
data-nginx-stateful-1    Bound    pvc-def456...                             1Gi        RWO            gp2            4m
data-nginx-stateful-2    Bound    pvc-ghi789...                             1Gi        RWO            gp2            3m
```

## Scaling StatefulSets

### Scale Up (Sequential)
```bash
$ kubectl scale statefulset nginx-stateful --replicas=5
```

Watch the ordered creation:
```bash
$ kubectl get pods -l app=nginx-stateful -w
```

### Scale Down (Reverse Order)
```bash
$ kubectl scale statefulset nginx-stateful --replicas=2
```

StatefulSets scale down in reverse order (highest ordinal first).

## Updating StatefulSets

### Rolling Update Strategy
StatefulSets support rolling updates with ordered replacement:

```bash
$ kubectl patch statefulset nginx-stateful -p '{"spec":{"template":{"spec":{"containers":[{"name":"nginx","image":"nginx:1.22"}]}}}}'
```

Watch the ordered update:
```bash
$ kubectl rollout status statefulset/nginx-stateful
```

### Update Strategies
```yaml
spec:
  updateStrategy:
    type: RollingUpdate
    rollingUpdate:
      partition: 0  # Update all pods (default)
```

Set `partition: 2` to only update pods with ordinal >= 2.

## Real-World Example: MySQL StatefulSet

Let's examine the MySQL StatefulSet from the retail application:

```bash
$ kubectl get statefulset -n catalog catalog-mysql -o yaml
```

Key features:
- **Persistent storage** - Data survives pod restarts
- **Stable hostname** - `catalog-mysql-0.catalog-mysql.catalog.svc.cluster.local`
- **Initialization** - Uses init containers for setup
- **Health checks** - Liveness and readiness probes

## StatefulSet Patterns

### Master-Slave Databases
```yaml
spec:
  template:
    spec:
      initContainers:
      - name: init-mysql
        image: mysql:5.7
        command:
        - bash
        - "-c"
        - |
          set -ex
          # Generate mysql server-id from pod ordinal index
          [[ `hostname` =~ -([0-9]+)$ ]] || exit 1
          ordinal=${BASH_REMATCH[1]}
          echo [mysqld] > /mnt/conf.d/server-id.cnf
          echo server-id=$((100 + $ordinal)) >> /mnt/conf.d/server-id.cnf
```

### Distributed Systems
For systems like Kafka or Elasticsearch:
- Use pod ordinals for broker/node IDs
- Configure cluster membership based on predictable hostnames
- Handle bootstrap and discovery logic

## Troubleshooting StatefulSets

### Pod Stuck in Pending
```bash
$ kubectl describe pod nginx-stateful-1
# Check for PVC binding issues, resource constraints
```

### Storage Issues
```bash
$ kubectl get pvc
$ kubectl describe pvc data-nginx-stateful-0
```

### Network Identity Problems
```bash
$ kubectl get service nginx-headless
$ kubectl describe service nginx-headless
```

### Ordered Deployment Issues
StatefulSets wait for each pod to be ready before creating the next:
```bash
$ kubectl get pods -l app=nginx-stateful
$ kubectl describe pod nginx-stateful-0  # Check why it's not ready
```

## Best Practices

### 1. Always Use Headless Services
```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-app-headless
spec:
  clusterIP: None  # Required for StatefulSets
```

### 2. Configure Proper Health Checks
```yaml
livenessProbe:
  exec:
    command: ["mysqladmin", "ping"]
  initialDelaySeconds: 30
  periodSeconds: 10
readinessProbe:
  exec:
    command: ["mysql", "-h", "127.0.0.1", "-e", "SELECT 1"]
  initialDelaySeconds: 5
  periodSeconds: 2
```

### 3. Use Init Containers for Setup
```yaml
initContainers:
- name: setup
  image: busybox
  command: ['sh', '-c', 'setup-script.sh']
```

### 4. Plan for Storage
- Choose appropriate storage classes
- Consider backup and recovery strategies
- Monitor storage usage

### 5. Handle Graceful Shutdown
```yaml
spec:
  template:
    spec:
      terminationGracePeriodSeconds: 60
      containers:
      - name: app
        lifecycle:
          preStop:
            exec:
              command: ["/bin/sh", "-c", "graceful-shutdown.sh"]
```

## Cleanup

Remove the StatefulSet and related resources:

```bash
$ kubectl delete statefulset nginx-stateful
$ kubectl delete service nginx-headless
$ kubectl delete pvc -l app=nginx-stateful
```

Note: PVCs are not automatically deleted when you delete a StatefulSet.

## What's Next?

Now that you understand StatefulSets for stateful applications, let's learn about [DaemonSets](./daemonsets) for running system services on every node in your cluster.