---
title: "Using Amazon DynamoDB"
sidebar_position: 32
---

The first step in this process is to re-configure the carts service to use a DynamoDB table that has already been created for us. The application loads most of its configurations from a ConfigMap. Let's take look at it:

```bash
$ kubectl -n carts get -o yaml cm carts
apiVersion: v1
data:
  AWS_ACCESS_KEY_ID: key
  AWS_SECRET_ACCESS_KEY: secret
  RETAIL_CART_PERSISTENCE_DYNAMODB_CREATE_TABLE: "true"
  RETAIL_CART_PERSISTENCE_DYNAMODB_ENDPOINT: http://carts-dynamodb:8000
  RETAIL_CART_PERSISTENCE_DYNAMODB_TABLE_NAME: Items
  RETAIL_CART_PERSISTENCE_PROVIDER: dynamodb
kind: ConfigMap
metadata:
  name: carts
  namespace: carts
```

The following kustomization overwrites the ConfigMap removing the DynamoDB endpoint configuration. It tells the SDK to use the real DynamoDB service instead of our test Pod. We've also configured the DynamoDB table name that's already been created for us. The table name is being pulled from the environment variable `RETAIL_CART_PERSISTENCE_DYNAMODB_TABLE_NAME`.

```kustomization
modules/security/eks-pod-identity/dynamo/kustomization.yaml
ConfigMap/carts
```

Let's set the DynamoDB table name and run Kustomize to use the real DynamoDB service:

```bash
$ export CARTS_DYNAMODB_TABLENAME=${EKS_CLUSTER_NAME}-carts && echo $CARTS_DYNAMODB_TABLENAME
eks-workshop-auto-carts
$ kubectl kustomize ~/environment/eks-workshop/modules/security/eks-pod-identity/dynamo \
  | envsubst | kubectl apply -f-
```

This will overwrite our ConfigMap with new values:

```bash
$ kubectl -n carts get cm carts -o yaml
apiVersion: v1
data:
  AWS_REGION: us-west-2
  RETAIL_CART_PERSISTENCE_DYNAMODB_TABLE_NAME: eks-workshop-auto-carts
  RETAIL_CART_PERSISTENCE_PROVIDER: dynamodb
kind: ConfigMap
metadata:
  labels:
    app: carts
  name: carts
  namespace: carts
```

Now, we need to recycle all the carts pods to pick up our new ConfigMap contents:

```bash expectError=true hook=enable-dynamo
$ kubectl rollout restart -n carts deployment/carts
deployment.apps/carts restarted
$ kubectl rollout status -n carts deployment/carts --timeout=20s
Waiting for deployment "carts" rollout to finish: 1 old replicas are pending termination...
error: timed out waiting for the condition
```

It looks like our change failed to deploy properly. We can confirm this by looking at the Pods:

```bash
$ kubectl -n carts get pod
NAME                              READY   STATUS             RESTARTS        AGE
carts-5d486d7cf7-8qxf9            1/1     Running            0               5m49s
carts-df76875ff-7jkhr             0/1     CrashLoopBackOff   3 (36s ago)     2m2s
carts-dynamodb-698674dcc6-hw2bg   1/1     Running            0               20m
```

What's gone wrong?
