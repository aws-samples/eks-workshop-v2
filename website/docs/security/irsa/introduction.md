---
title: "Introduction"
sidebar_position: 10
---

Run the following command to setup the EKS cluster for this module:

```bash timeout=300 wait=30
reset-environment
```

The `carts` component of our architecture is currently using a lightweight version of Amazon DynamoDB running as a container in the EKS cluster. You can see this by running the following command:

```bash
kubectl -n carts get pod 
NAME                              READY   STATUS    RESTARTS        AGE
carts-5d7fc9d8f-xm4hs             1/1     Running   0               14m
carts-dynamodb-698674dcc6-hw2bg   1/1     Running   0               14m
```

In the case above, the Pod `carts-dynamodb-698674dcc6-hw2bg` is our lightweight DynamoDB service. We can verify our `carts` application is using this by inspecting its environment:

```bash
kubectl -n carts exec deployment/carts -- env \
  | grep CARTS_DYNAMODB_ENDPOINT
CARTS_DYNAMODB_ENDPOINT=http://carts-dynamodb:8000
```

This approach can be useful for testing, but we want to move our application to use the fully managed Amazon DynamoDB service.