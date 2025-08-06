---
title: Workloads
sidebar_position: 10
---

# Advanced Workloads

While Deployments handle most stateless applications, Kubernetes provides specialized workload types for different use cases. In this section, you'll learn about StatefulSets, DaemonSets, and Jobs.

## Workload Types Overview

| Workload Type | Use Case | Key Features |
|---------------|----------|--------------|
| **Deployment** | Stateless applications | Scaling, rolling updates, replicas |
| **StatefulSet** | Stateful applications | Persistent storage, stable network identity |
| **DaemonSet** | Node-level services | One pod per node, system services |
| **Job** | Batch processing | Run to completion, parallel execution |
| **CronJob** | Scheduled tasks | Time-based scheduling, recurring jobs |

## When to Use Each Type

### StatefulSets
- **Databases** - MySQL, PostgreSQL, MongoDB
- **Distributed systems** - Kafka, Elasticsearch, Cassandra
- **Applications requiring** - Persistent storage, stable hostnames, ordered deployment

### DaemonSets
- **Monitoring agents** - Node Exporter, Datadog agent
- **Log collectors** - Fluentd, Filebeat
- **Network plugins** - CNI plugins, kube-proxy
- **Security scanners** - Vulnerability scanners, compliance tools

### Jobs and CronJobs
- **Data processing** - ETL jobs, batch analytics
- **Maintenance tasks** - Database backups, cleanup scripts
- **Initialization** - Database migrations, setup scripts

## Sections

- **[StatefulSets](./statefulsets)** - Manage stateful applications with persistent storage
- **[DaemonSets](./daemonsets)** - Run system services on every node
- **[Jobs](./jobs)** - Execute batch processing and scheduled tasks

## Real-World Examples

In the retail application you deployed, you've already seen StatefulSets in action:

```bash
$ kubectl get statefulsets -l app.kubernetes.io/created-by=eks-workshop -A
NAMESPACE   NAME                READY   AGE
catalog     catalog-mysql       1/1     30m
checkout    checkout-redis      1/1     30m
orders      orders-postgresql   1/1     30m
```

These databases use StatefulSets because they need:
- **Persistent storage** - Data survives pod restarts
- **Stable network identity** - Consistent hostnames for clustering
- **Ordered deployment** - Primary/replica relationships

Let's start by exploring [StatefulSets](./statefulsets) to understand how they differ from Deployments.