---
title: DaemonSets
sidebar_position: 20
---

# DaemonSets

DaemonSets ensure that a copy of a pod runs on every node (or a subset of nodes) in your cluster. They're perfect for system-level services that need to run cluster-wide.

## What are DaemonSets?

DaemonSets automatically:
- **Deploy one pod per node** - Ensures coverage across the cluster
- **Handle node changes** - Automatically deploy to new nodes
- **Manage pod lifecycle** - Replace failed pods automatically
- **Support node selection** - Run only on specific nodes if needed

## Common Use Cases

### System Services
- **Log collectors** - Fluentd, Filebeat, Logstash
- **Monitoring agents** - Node Exporter, Datadog agent, New Relic
- **Network plugins** - CNI plugins, kube-proxy
- **Storage drivers** - CSI drivers, Gluster clients

### Security and Compliance
- **Security scanners** - Vulnerability scanners, compliance agents
- **Policy enforcement** - OPA Gatekeeper, Falco
- **Certificate management** - Cert-manager components

### Performance and Debugging
- **Performance monitoring** - System performance collectors
- **Debugging tools** - Network troubleshooting pods
- **Cache warming** - Application cache pre-loading

## Creating Your First DaemonSet

Let's create a simple DaemonSet that runs a log collector:

```bash
$ cat << EOF | kubectl apply -f -
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: log-collector
  labels:
    app: log-collector
spec:
  selector:
    matchLabels:
      app: log-collector
  template:
    metadata:
      labels:
        app: log-collector
    spec:
      containers:
      - name: log-collector
        image: busybox
        command: ['sh', '-c', 'while true; do echo "Collecting logs from $(hostname)"; sleep 30; done']
        resources:
          requests:
            memory: "64Mi"
            cpu: "100m"
          limits:
            memory: "128Mi"
            cpu: "200m"
        volumeMounts:
        - name: varlog
          mountPath: /var/log
          readOnly: true
        - name: varlibdockercontainers
          mountPath: /var/lib/docker/containers
          readOnly: true
      volumes:
      - name: varlog
        hostPath:
          path: /var/log
      - name: varlibdockercontainers
        hostPath:
          path: /var/lib/docker/containers
      tolerations:
      - key: node-role.kubernetes.io/control-plane
        operator: Exists
        effect: NoSchedule
EOF
```

## Observing DaemonSet Behavior

### Check Pod Distribution
```bash
$ kubectl get pods -l app=log-collector -o wide
NAME                  READY   STATUS    RESTARTS   AGE   IP           NODE
log-collector-abc12   1/1     Running   0          1m    10.244.1.5   worker-1
log-collector-def34   1/1     Running   0          1m    10.244.2.3   worker-2
log-collector-ghi56   1/1     Running   0          1m    10.244.3.7   worker-3
```

Notice how there's exactly one pod per node.

### View DaemonSet Status
```bash
$ kubectl get daemonset log-collector
NAME            DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR   AGE
log-collector   3         3         3       3            3           <none>          2m
```

### Check Logs from All Nodes
```bash
$ kubectl logs -l app=log-collector --tail=5
```

## Node Selection

### Node Selectors
Run DaemonSet only on specific nodes:

```yaml
spec:
  template:
    spec:
      nodeSelector:
        node-type: worker  # Only on nodes with this label
```

### Node Affinity
More complex node selection:

```yaml
spec:
  template:
    spec:
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: kubernetes.io/arch
                operator: In
                values: ["amd64"]
```

### Tolerations
Run on nodes with taints (like control plane nodes):

```yaml
spec:
  template:
    spec:
      tolerations:
      - key: node-role.kubernetes.io/control-plane
        operator: Exists
        effect: NoSchedule
      - key: node.kubernetes.io/disk-pressure
        operator: Exists
        effect: NoSchedule
```

## Real-World Example: Monitoring Agent

Let's create a more realistic DaemonSet for a monitoring agent:

```bash
$ cat << EOF | kubectl apply -f -
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: node-monitor
  labels:
    app: node-monitor
spec:
  selector:
    matchLabels:
      app: node-monitor
  template:
    metadata:
      labels:
        app: node-monitor
    spec:
      hostNetwork: true  # Use host networking
      hostPID: true      # Access host processes
      containers:
      - name: node-monitor
        image: prom/node-exporter:latest
        ports:
        - containerPort: 9100
          hostPort: 9100
        args:
        - '--path.procfs=/host/proc'
        - '--path.sysfs=/host/sys'
        - '--collector.filesystem.ignored-mount-points=^/(sys|proc|dev|host|etc)($$|/)'
        resources:
          requests:
            memory: "100Mi"
            cpu: "100m"
          limits:
            memory: "200Mi"
            cpu: "200m"
        volumeMounts:
        - name: proc
          mountPath: /host/proc
          readOnly: true
        - name: sys
          mountPath: /host/sys
          readOnly: true
        - name: root
          mountPath: /rootfs
          readOnly: true
      volumes:
      - name: proc
        hostPath:
          path: /proc
      - name: sys
        hostPath:
          path: /sys
      - name: root
        hostPath:
          path: /
      tolerations:
      - operator: Exists  # Tolerate all taints
EOF
```

This DaemonSet:
- **Uses host networking** - Direct access to node network
- **Mounts host paths** - Access to system metrics
- **Tolerates all taints** - Runs on all nodes including control plane
- **Exposes metrics** - On port 9100 for Prometheus

## Updating DaemonSets

### Rolling Update (Default)
```bash
$ kubectl patch daemonset node-monitor -p '{"spec":{"template":{"spec":{"containers":[{"name":"node-monitor","image":"prom/node-exporter:v1.3.1"}]}}}}'
```

### Update Strategy Configuration
```yaml
spec:
  updateStrategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1  # Update one node at a time
```

### OnDelete Strategy
```yaml
spec:
  updateStrategy:
    type: OnDelete  # Manual pod deletion required for updates
```

## DaemonSet in EKS

### AWS-Specific Examples
In EKS, you'll commonly see DaemonSets for:

- **AWS Load Balancer Controller** - Manages ALB/NLB
- **EBS CSI Driver** - Manages EBS volumes
- **VPC CNI** - Manages pod networking
- **CloudWatch Agent** - Collects metrics and logs

### Check EKS System DaemonSets
```bash
$ kubectl get daemonsets -n kube-system
NAME         DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR            AGE
aws-node     3         3         3       3            3           <none>                   1d
kube-proxy   3         3         3       3            3           kubernetes.io/os=linux   1d
```

## Troubleshooting DaemonSets

### Pods Not Scheduling
```bash
$ kubectl describe daemonset log-collector
# Look for events and conditions

$ kubectl get nodes --show-labels
# Check node labels and taints
```

### Resource Issues
```bash
$ kubectl top nodes
# Check node resource usage

$ kubectl describe node <node-name>
# Look for resource pressure
```

### Permission Problems
```bash
$ kubectl get pods -l app=log-collector
$ kubectl logs <pod-name>
# Check for permission errors
```

### Node Selector Issues
```bash
$ kubectl get nodes -l node-type=worker
# Verify nodes have required labels
```

## Best Practices

### 1. Resource Management
Always set resource requests and limits:
```yaml
resources:
  requests:
    memory: "64Mi"
    cpu: "100m"
  limits:
    memory: "128Mi"
    cpu: "200m"
```

### 2. Security Context
Run with minimal privileges:
```yaml
securityContext:
  runAsNonRoot: true
  runAsUser: 1000
  readOnlyRootFilesystem: true
```

### 3. Health Checks
Configure probes for reliability:
```yaml
livenessProbe:
  httpGet:
    path: /health
    port: 8080
  initialDelaySeconds: 30
  periodSeconds: 10
readinessProbe:
  httpGet:
    path: /ready
    port: 8080
  initialDelaySeconds: 5
  periodSeconds: 5
```

### 4. Tolerations
Handle node taints appropriately:
```yaml
tolerations:
- key: node.kubernetes.io/not-ready
  operator: Exists
  effect: NoExecute
  tolerationSeconds: 300
```

### 5. Host Access
Be careful with host access:
```yaml
# Only when necessary
hostNetwork: true
hostPID: true
hostIPC: true
```

### 6. Volume Mounts
Use read-only mounts when possible:
```yaml
volumeMounts:
- name: logs
  mountPath: /var/log
  readOnly: true
```

## Monitoring DaemonSets

### Check Status
```bash
$ kubectl get daemonsets
$ kubectl describe daemonset <name>
```

### Pod Distribution
```bash
$ kubectl get pods -l app=<daemonset-label> -o wide
```

### Resource Usage
```bash
$ kubectl top pods -l app=<daemonset-label>
```

### Events
```bash
$ kubectl get events --field-selector involvedObject.kind=DaemonSet
```

## Cleanup

Remove the DaemonSets we created:

```bash
$ kubectl delete daemonset log-collector node-monitor
```

## What's Next?

Now that you understand DaemonSets for cluster-wide services, let's learn about [Jobs](./jobs) for batch processing and scheduled tasks.