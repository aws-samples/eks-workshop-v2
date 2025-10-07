---
title: DaemonSets
sidebar_position: 33
sidebar_custom_props: { "module": true }
---

# DaemonSets

::required-time

:::tip Before you start
Prepare your environment for this section:

```bash timeout=300 wait=10
$ prepare-environment introduction/basics/daemonsets
```

:::

**DaemonSets** ensure that a copy of a pod runs on **every node** (or a subset of nodes) in your cluster. They are ideal for system-level services that must operate on all nodes, such as logging, monitoring, and network agents.

Key benefits:
- **Cover all nodes** - One Pod per node
- **Scale automatically with nodes** - New nodes get pods, removed nodes lose pods
- **Run system services** - Ideal for logging, monitoring, and networking
- **Target specific nodes** - Using selectors or affinity
- **Access host resources** - Like logs, metrics, and system files

## When to Use DaemonSets
Daemonsets are perfect for services that need to run on every node or a subset of nodes:
- **Log collectors** - Fluentd, Filebeat, Fluent Bit
- **Monitoring agents** - Node Exporter, Datadog agent, New Relic
- **Network plugins** - CNI plugins, load balancer controllers
- **Security agents** - Antivirus scanners, compliance tools
- **Storage daemons** - Distributed storage agents

## Deploying a DaemonSet

Let's create a simple log collector DaemonSet that runs on all nodes and collects logs from the host filesystem:

::yaml{file="manifests/modules/introduction/basics/daemonsets/log-collector.yaml" paths="kind,metadata.name,spec.selector,spec.template.spec.containers.0.volumeMounts,spec.template.spec.volumes" title="log-collector.yaml"}

1. `kind: DaemonSet`: Creates a DaemonSet controller
2. `metadata.name`: Name of the DaemonSet (`log-collector`)
3. `spec.selector`: How DaemonSet finds its pods (by labels)
4. `spec.template.spec.containers.0.volumeMounts`: How container accesses node files
5. `spec.template.spec.volumes`: Host paths for accessing node logs

Key DaemonSet characteristics:
- No `replicas` field - Kubernetes automatically runs one pod per node
- Pods automatically scale as nodes are added or removed.
- `hostPath` volumes allow Pods to access node files, if required.
- Typically deployed in `kube-system` namespace for system services, but can run in other namespaces.

Deploy the DaemonSet:
```bash
$ kubectl apply -f ~/environment/eks-workshop/modules/introduction/basics/daemonsets/log-collector.yaml
```

## Inspecting Your DaemonSet

Check DaemonSet status:
```bash
$ kubectl get daemonset -n kube-system
NAME            DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   AGE
log-collector   3         3         3       3            3           2m
```
> You'll see output showing desired vs current pods:

View the pods across all nodes:
```bash
$ kubectl get pods -n kube-system -l app=log-collector -o wide
NAME                  READY   STATUS    NODE           AGE
log-collector-abc12   1/1     Running   ip-10-42-1-1   2m
log-collector-def34   1/1     Running   ip-10-42-2-1   2m
log-collector-ghi56   1/1     Running   ip-10-42-3-1   2m
```
> Notice one pod per node

## Node Selection

Target specific nodes using nodeSelector:

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

Or use nodeAffinity for more complex rules:

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
Use nodeSelector for simple label matches and nodeAffinity for more complex scheduling requirements.

## DaemonSets vs Other Controllers

| Controller | Purpose | Replica Count | Node Placement | Use Case |
|------------|---------|---------------|----------------|----------|
| DaemonSet  | One Pod per node | Automatic | All nodes or subset | System services |
| Deployment | Multiple interchangeable Pods | Configurable | Any node | Stateless apps |
| StatefulSet | Pods with stable identity | Configurable | Any node | Stateful apps |

:::info
DaemonSets are ideal for services that must run on every node or a specific set of nodes.
:::

## Key Points to Remember

* DaemonSets automatically run one pod per node
* Perfect for system-level services like logging and monitoring
* No need to specify replica count - it's automatic
* Can access node resources through hostPath volumes
* Use node selectors to target specific nodes
* Pods are automatically added/removed as nodes join/leave
* Ideal for consistent system functionality across all nodes