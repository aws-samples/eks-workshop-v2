---
title: StatefulSets
sidebar_position: 32
---

# StatefulSets

**StatefulSets** manage stateful applications that need persistent identity and storage. Unlike deployments where pods are interchangeable, each pod in a StatefulSet has a unique, stable identity.

Key benefits:
- **Stable identities** - Pods get predictable names (mysql-0, mysql-1, mysql-2)
- **Persistent storage** - Each pod can have its own persistent volume
- **Ordered operations** - Pods are created and deleted in sequence
- **Stable networking** - Each pod keeps the same network identity
- **Ordered updates** - Rolling updates happen one pod at a time

## Deploying a StatefulSet

Let's deploy a MySQL database for our catalog service:

::yaml{file="manifests/base-application/catalog/statefulset-mysql.yaml" paths="kind,metadata.name,spec.serviceName,spec.replicas" title="statefulset.yaml"}

1. `kind: StatefulSet`: Creates a StatefulSet controller
2. `metadata.name`: Name of the StatefulSet (catalog-mysql)
3. `spec.serviceName`: Required for stable network identities
4. `spec.replicas`: Number of pods to run (1 for this database)

Deploy the database:
```bash
$ kubectl apply -f ~/environment/eks-workshop/manifests/base-application/catalog/
```

## Inspecting Your StatefulSet

Check StatefulSet status:
```bash
$ kubectl get statefulset -n catalog
```

You'll see output like:
```
NAME            READY   AGE
catalog-mysql   1/1     2m
```

View the pods created:
```bash
$ kubectl get pods -n catalog
```

Notice the predictable pod name with a number suffix:
```
NAME              READY   STATUS    RESTARTS   AGE
catalog-mysql-0   1/1     Running   0          2m
```

Get detailed information about the StatefulSet:
```bash
$ kubectl describe statefulset -n catalog catalog-mysql
```

This shows the pod template, volume mounts, and current status of the StatefulSet.

## Scaling Your StatefulSet

Scale up to 3 replicas:
```bash
$ kubectl scale statefulset -n catalog catalog-mysql --replicas=3
```

Watch the ordered creation:
```bash
$ kubectl get pods -n catalog -w
```

You'll see pods created one at a time in order:
```
NAME              READY   STATUS    RESTARTS   AGE
catalog-mysql-0   1/1     Running   0          5m
catalog-mysql-1   0/1     Pending   0          10s
catalog-mysql-1   1/1     Running   0          30s
catalog-mysql-2   0/1     Pending   0          5s
catalog-mysql-2   1/1     Running   0          25s
```

Scale back down:
```bash
$ kubectl scale statefulset -n catalog catalog-mysql --replicas=1
```

Pods are deleted in reverse order (2, then 1, keeping 0).

## StatefulSets vs Deployments

**StatefulSets:**
- Pods have unique, stable names (mysql-0, mysql-1)
- Each pod can have persistent storage
- Ordered creation and deletion
- Stable network identities

**Deployments:**
- Pods are interchangeable with random names
- Typically use ephemeral storage
- Pods can be created/deleted in any order
- No stable network identities

## Key Points to Remember

* StatefulSets provide stable, unique identities for each pod
* Perfect for databases, message queues, and clustered applications
* Each pod can have its own persistent storage that survives restarts
* Operations happen in order - creation (0→1→2) and deletion (2→1→0)
* Pod names are predictable and never change

## Next Steps

Now that you understand StatefulSets, explore other workload controllers:
- **[DaemonSets](./daemonsets)** - For node-level services that run everywhere
- **[Jobs](./jobs)** - For batch processing and scheduled tasks

Or learn about **[Services](../services)** - how to provide stable network access to your StatefulSets.