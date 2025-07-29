---
title: "Using DynamoDB"
sidebar_position: 22
---

The first step in this process is to re-configure the `carts` service to use a DynamoDB table that has already been created for us. The application loads most of its confirmation from a ConfigMap, lets take look at it:

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

The following kustomization overwrites the ConfigMap, removing the DynamoDB endpoint configuration which tells the SDK to default to the real DynamoDB service instead of our test Pod. We've also provided it with the name of the DynamoDB table thats been created already for us which is being pulled from the environment variable `RETAIL_CART_PERSISTENCE_DYNAMODB_TABLE_NAME`.

```kustomization
modules/security/irsa/dynamo/kustomization.yaml
ConfigMap/carts
```

Let's check the value of `CARTS_DYNAMODB_TABLENAME` then run Kustomize to use the real DynamoDB service:

```bash
$ echo $CARTS_DYNAMODB_TABLENAME
eks-workshop-carts
$ kubectl kustomize ~/environment/eks-workshop/modules/security/irsa/dynamo \
  | envsubst | kubectl apply -f-
```

This will overwrite our ConfigMap with new values:

```bash
$ kubectl get -n carts cm carts -o yaml
apiVersion: v1
data:
  RETAIL_CART_PERSISTENCE_DYNAMODB_TABLE_NAME: eks-workshop-carts
  RETAIL_CART_PERSISTENCE_PROVIDER: dynamodb
kind: ConfigMap
metadata:
  labels:
    app: carts
  name: carts
  namespace: carts
```

Now we need to recycle all the carts Pods to pick up our new ConfigMap contents:

```bash expectError=true hook=enable-dynamo
$ kubectl rollout restart -n carts deployment/carts
deployment.apps/carts restarted
$ kubectl rollout status -n carts deployment/carts --timeout=20s
Waiting for deployment "carts" rollout to finish: 1 old replicas are pending termination...
error: timed out waiting for the condition
```

It looks like our change failed to deploy properly, we can confirm this by looking at the Pods:

```bash
$ kubectl -n carts get pod
NAME                              READY   STATUS             RESTARTS        AGE
carts-5d486d7cf7-8qxf9            1/1     Running            0               5m49s
carts-df76875ff-7jkhr             0/1     CrashLoopBackOff   3 (36s ago)     2m2s
carts-dynamodb-698674dcc6-hw2bg   1/1     Running            0               20m
```

What's gone wrong?
