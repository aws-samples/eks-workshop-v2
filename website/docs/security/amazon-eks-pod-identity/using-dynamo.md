---
title: "Using Amazon DynamoDB"
sidebar_position: 20
---

The first step in this process is to re-configure the carts service to use a DynamoDB table that has already been created for us. The application loads most of its confirmation from a ConfigMap, lets take look at it:

```bash
$ kubectl -n carts get -o yaml cm carts
apiVersion: v1
data:
  AWS_ACCESS_KEY_ID: key
  AWS_SECRET_ACCESS_KEY: secret
  CARTS_DYNAMODB_CREATETABLE: true
  CARTS_DYNAMODB_ENDPOINT: http://carts-dynamodb:8000
  CARTS_DYNAMODB_TABLENAME: Items
kind: ConfigMap
metadata:
  name: carts
  namespace: carts
```

Also, check the current status of the application the using the browser. A `LoadBalancer` type service named `ui-nlb` is provisioned in the `ui` namespace from which the application's UI can be accessed.

```bash
$ kubectl -n ui get service ui-nlb -o jsonpath='{.status.loadBalancer.ingress[*].hostname}{"\n"}'
k8s-ui-uinlb-647e781087-6717c5049aa96bd9.elb.us-west-2.amazonaws.com
```

Use the generated URL from the command above to open the UI in your browser. It should open the the Retail Store like shown below.

![Home](../../../static/img/sample-app-screens/home.png)

Now, the following kustomization overwrites the ConfigMap, removing the DynamoDB endpoint configuration which tells the SDK to default to the real DynamoDB service instead of our test Pod. We've also provided it with the name of the DynamoDB table thats been created already for us which is being pulled from the environment variable `CARTS_DYNAMODB_TABLENAME`.

```kustomization
modules/security/eks-pod-identity/dynamo/kustomization.yaml
ConfigMap/carts
```

Let's check the value of `CARTS_DYNAMODB_TABLENAME` then run Kustomize to use the real DynamoDB service:

```bash
$ echo $CARTS_DYNAMODB_TABLENAME
eks-workshop-carts
$ kubectl kustomize ~/environment/eks-workshop/modules/security/eks-pod-identity/dynamo \
  | envsubst | kubectl apply -f-
```

This will overwrite our ConfigMap with new values:

```bash
$ kubectl -n carts get cm carts -o yaml
apiVersion: v1
data:
  CARTS_DYNAMODB_TABLENAME: eks-workshop-carts
kind: ConfigMap
metadata:
  labels:
    app: carts
  name: carts
  namespace: carts
```

We'll need to recycle all the Pods of the `carts` application to pick up our new ConfigMap contents.

```bash hook=enable-dynamo hookTimeout=430
$ kubectl -n carts rollout restart deployment/carts
deployment.apps/carts restarted
$ kubectl -n carts rollout status deployment/carts
```

So now our application should be using DynamoDB right? Try to load it up in the browser using the URL outputed in the previous command, and navigate to the shopping cart.

```bash
$ kubectl -n ui get service ui-nlb -o jsonpath='{.status.loadBalancer.ingress[*].hostname}{"\n"}'
k8s-ui-uinlb-647e781087-6717c5049aa96bd9.elb.us-west-2.amazonaws.com
```

![Error500](../../../static/img/sample-app-screens/error-500.png)

The shopping cart page is not accessible! What's gone wrong?
