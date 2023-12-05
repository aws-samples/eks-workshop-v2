---
title: "Introduction"
sidebar_position: 10
---

The `catalog` component of our architecture uses a MySQL database as its storage backend. The way in which the way the catalog API is currently deployed uses a database deployed as a Pod in the EKS cluster.

You can see this by running the following command:

```bash
$ kubectl -n catalog get pod 
NAME                              READY   STATUS    RESTARTS        AGE
catalog-5d7fc9d8f-xm4hs             1/1     Running   0               14m
catalog-mysql-0                     1/1     Running   0               14m
```

In the case above, the Pod `catalog-mysql-0` is a MySQL Pod. We can verify our `catalog` application is using this by inspecting its environment:

```bash
$ kubectl -n catalog exec deployment/catalog -- env \
  | grep DB_ENDPOINT
DB_ENDPOINT=catalog-mysql:3306
```

We want to migrate our application to use the fully managed Amazon RDS service in order to take full advantage of the scale and reliability it offers.
