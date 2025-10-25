---
title: "Introduction"
sidebar_position: 10
---

The `catalog` component of our architecture uses a MySQL database as its storage backend. Currently, the catalog API is deployed with a database running as a Pod within the EKS cluster.

You can see this by running the following command:

```bash
$ kubectl -n catalog get pod
NAME                                READY   STATUS    RESTARTS        AGE
catalog-5d7fc9d8f-xm4hs             1/1     Running   0               14m
catalog-mysql-0                     1/1     Running   0               14m
```

In the output above, the Pod `catalog-mysql-0` is our MySQL database. We can verify that the `catalog` application is using this by inspecting its environment:

```bash
$ kubectl -n catalog exec deployment/catalog -- env \
  | grep RETAIL_CATALOG_PERSISTENCE_ENDPOINT
RETAIL_CATALOG_PERSISTENCE_ENDPOINT=catalog-mysql:3306
```

We want to migrate our application to use the fully managed Amazon RDS service in order to take advantage of its scale and reliability features.
