---
title: "Introduction"
sidebar_position: 31
---

The `carts` component of our architecture uses Amazon DynamoDB as its storage backend, which is a common use-case you'll find for non-relational databases integration with Amazon EKS. Currently, the carts API is deployed with a [lightweight version of Amazon DynamoDB](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/DynamoDBLocal.html) running as a container in the EKS cluster.

You can see this by running the following command:

```bash
$ kubectl -n carts get pod
NAME                              READY   STATUS    RESTARTS        AGE
carts-5d7fc9d8f-xm4hs             1/1     Running   0               14m
carts-dynamodb-698674dcc6-hw2bg   1/1     Running   0               14m
```

In the output above, the Pod `carts-dynamodb-698674dcc6-hw2bg` is our lightweight DynamoDB service. We can verify our `carts` application is using this by inspecting its environment:

```bash
$ kubectl -n carts exec deployment/carts -- env | grep RETAIL_CART_PERSISTENCE_DYNAMODB_ENDPOINT
RETAIL_CART_PERSISTENCE_DYNAMODB_ENDPOINT=http://carts-dynamodb:8000
```

While this approach can be useful for testing, we want to migrate our application to use the fully managed Amazon DynamoDB service to take full advantage of the scale and reliability it offers. In the following sections, we'll reconfigure our application to use Amazon DynamoDB and implement EKS Pod Identity to provide secure access to AWS services.
