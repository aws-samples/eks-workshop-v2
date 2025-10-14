---
title: Current storage configuration
sidebar_position: 10
---

Let's examine how the catalog MySQL database currently stores its data. The catalog service uses MySQL as its backend database, and we'll check its current storage configuration.

First, let's look at the StatefulSet for the catalog MySQL database:

```bash
$ kubectl describe statefulset -n catalog catalog-mysql
Name:               catalog-mysql
Namespace:          catalog
[...]
  Containers:
   mysql:
    Image:      public.ecr.aws/docker/library/mysql:8.0
    Port:       3306/TCP
    Mounts:
      /var/lib/mysql from data (rw)
  Volumes:
   data:
    Type:       EmptyDir (a temporary directory that shares a pod's lifetime)
[...]
```

The StatefulSet currently uses an [EmptyDir volume](https://kubernetes.io/docs/concepts/storage/volumes/#emptydir) that exists only for the Pod's lifetime. This means:

- When the Pod is terminated, all database data is permanently lost
- The database starts fresh with each pod restart
- There's no data persistence across pod lifecycle events

This is not suitable for a production database. In the next section, we'll configure persistent storage using Amazon EBS to ensure our database data survives pod restarts and failures.
