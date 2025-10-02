---
title: DaemonSets
sidebar_position: 33
---

# DaemonSets

**DaemonSets** ensure that a copy of a pod runs on every node (or selected nodes) in your cluster. They're perfect for system-level services that need to run everywhere.

Key benefits:
- **Node coverage** - Automatically runs one pod per node
- **Automatic scaling** - New nodes get pods, removed nodes lose pods
- **System services** - Perfect for logging, monitoring, and networking
- **Node selection** - Can target specific nodes with selectors
- **Host access** - Can access node resources like logs and metrics

## When to Use DaemonSets

Use DaemonSets for services that need to run on every node:
- **Log collectors** - Fluentd, Filebeat, Fluent Bit
- **Monitoring agents** - Node Exporter, Datadog agent, New Relic
- **Network plugins** - CNI plugins, load balancer controllers
- **Security agents** - Antivirus scanners, compliance tools
- **Storage daemons** - Distributed storage agents

## Deploying a DaemonSet

Let's create a simple log collector DaemonSet:

::yaml{file="manifests/modules/introduction/basics/log-collector.yaml" paths="kind,metadata.name,spec.selector,spec.template.spec.containers.0.volumeMounts,spec.template.spec.volumes" title="log-collector.yaml"}

1. `kind: DaemonSet`: Creates a DaemonSet controller
2. `metadata.name`: Name of the DaemonSet (log-collector)
3. `spec.selector`: How DaemonSet finds its pods (by labels)
4. `spec.template.spec.containers.0.volumeMounts`: How container accesses node files
5. `spec.template.spec.volumes`: Host paths for accessing node logs

Key DaemonSet characteristics:
- No `replicas` field - automatically runs one pod per node
- `hostPath` volumes - Access node filesystem for logs
- Typically deployed in `kube-system` namespace

Deploy the DaemonSet:
```bash
$ kubectl apply -f ~/environment/eks-workshop/modules/introduction/basics/log-collector.yaml
```

## Inspecting Your DaemonSet

Check DaemonSet status:
```bash
$ kubectl get daemonset -n kube-system
```

You'll see output showing desired vs current pods:
```
NAME            DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   AGE
log-collector   3         3         3       3            3           2m
```

View the pods across all nodes:
```bash
$ kubectl get pods -n kube-system -l app=log-collector -o wide
```

Notice one pod per node:
```
NAME                  READY   STATUS    NODE           AGE
log-collector-abc12   1/1     Running   ip-10-42-1-1   2m
log-collector-def34   1/1     Running   ip-10-42-2-1   2m
log-collector-ghi56   1/1     Running   ip-10-42-3-1   2m
```

## Node Selection

Target specific nodes using node selectors:

```yaml
spec:
  template:
    spec:
      nodeSelector:
        node-type: worker
      containers:
      - name: monitoring-agent
        image: monitoring:latest
```

Or use node affinity for more complex rules:

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
                values:
                - amd64
```

## Managing DaemonSets

**Update a DaemonSet:**
```bash
$ kubectl patch daemonset -n kube-system log-collector -p '{"spec":{"template":{"spec":{"containers":[{"name":"fluentd","image":"fluentd:v1.17"}]}}}}'
```

**Check rollout status:**
```bash
$ kubectl rollout status daemonset/log-collector -n kube-system
```

**View DaemonSet events:**
```bash
$ kubectl describe daemonset -n kube-system log-collector
```

## DaemonSets vs Other Controllers

**DaemonSets:**
- One pod per node automatically
- No replica count needed
- Perfect for system services
- Pods tied to specific nodes

**Deployments:**
- Configurable number of replicas
- Pods can run on any available node
- Perfect for application services
- Pods are interchangeable

**StatefulSets:**
- Configurable replicas with stable identities
- Pods have unique names and storage
- Perfect for stateful applications
- Ordered operations

## Key Points to Remember

* DaemonSets automatically run one pod per node
* Perfect for system-level services like logging and monitoring
* No need to specify replica count - it's automatic
* Can access node resources through hostPath volumes
* Use node selectors to target specific nodes
* Pods are automatically added/removed as nodes join/leave

## Next Steps

Now that you understand DaemonSets, explore other workload controllers:
- **[Jobs](./jobs)** - For batch processing and scheduled tasks

Or learn about **[Services](../services)** - how to provide network access to your workloads.