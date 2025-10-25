---
title: StatefulSets
sidebar_position: 32
---

# StatefulSets

**StatefulSets** manage applications that need **stable identities and persistent storage**. Unlike Deployments, where Pods are interchangeable, each Pod in a StatefulSet **keeps a unique, predictable identity** throughout its lifecycle.

They provide several important benefits for stateful applications:
- **Provide stable identities** - Pods get predictable names (mysql-0, mysql-1, mysql-2)
- **Enable persistent storage** - Each pod can have its own persistent volume
- **Ensure ordered operations** - Pods are created and deleted sequentially
- **Maintain stable networking** - Each pod keeps the same network identity
- **Support rolling updates in order** - Pods update one at a time

## Deploying a StatefulSet

Let's deploy a MySQL database for our catalog service:

The following YAML creates a StatefulSet running MySQL for the catalog service, with persistent storage and predictable Pod names.

::yaml{file="manifests/base-application/catalog/statefulset-mysql.yaml" paths="kind,metadata.name,spec.serviceName,spec.replicas" title="statefulset.yaml"}

1. `kind: StatefulSet`: Creates a StatefulSet controller
2. `metadata.name`: Name of the StatefulSet (catalog-mysql)
3. `spec.serviceName`: Required for stable network identities (creates a headless Service)
4. `spec.replicas`: Number of pods to run (1 for this example)

Deploy the database:
```bash
$ kubectl apply -k ~/environment/eks-workshop/base-application/catalog/
```

## Inspecting StatefulSet

Check StatefulSet status:
```bash
$ kubectl get statefulset -n catalog
NAME            READY   AGE
catalog-mysql   1/1     2m
```

View the pods created:
```bash
$ kubectl get pods -n catalog
NAME              READY   STATUS    RESTARTS   AGE
catalog-mysql-0   1/1     Running   0          2m
```
> Notice the predictable pod name with a number suffix

Get detailed information about the StatefulSet:
```bash
$ kubectl describe statefulset -n catalog catalog-mysql
```

The suffix (`-0`, `-1`, etc.) allows you to track each Pod individually for storage and network purposes.

## Scaling StatefulSet

Scale up to 3 replicas:
```bash
$ kubectl scale statefulset -n catalog catalog-mysql --replicas=3
$ kubectl get pods -n catalog
NAME              READY   STATUS    RESTARTS   AGE
catalog-mysql-0   1/1     Running   0          5m
catalog-mysql-1   0/1     Pending   0          10s
catalog-mysql-1   1/1     Running   0          30s
catalog-mysql-2   0/1     Pending   0          5s
catalog-mysql-2   1/1     Running   0          25s
```
You'll see pods created one at a time in order

Scale back down:
```bash
$ kubectl scale statefulset -n catalog catalog-mysql --replicas=1
```

Pods are deleted in reverse order (2, then 1, keeping 0), ensuring stability.

Kubernetes also ensures that **each Pod keeps its persistent volume**, even when scaled up or down.

## StatefulSets vs Deployments
| Feature           | StatefulSet                   | Deployment        |
| ----------------- | ----------------------------- | ----------------- |
| Pod Names         | Stable (`mysql-0`, `mysql-1`) | Random            |
| Storage           | Persistent per Pod            | Usually ephemeral |
| Creation/Deletion | Ordered                       | Any order         |
| Network Identity  | Stable                        | Dynamic           |
| Use Case          | Databases, message queues     | Stateless apps    |

:::info
StatefulSets are ideal for applications that require persistent identity, stable networking, and ordered operations.
:::

## Key Points to Remember

* StatefulSets provide stable, unique identities for each pod
* Perfect for databases, message queues, and clustered applications
* Each pod can have its own persistent storage that survives restarts
* Operations happen in order - creation (0→1→2) and deletion (2→1→0)
* Pod names are predictable and never change
* Use StatefulSets whenever your application needs identity, stability, and persistence.