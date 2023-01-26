---
title: "Using DynamoDB"
sidebar_position: 20
---

The first step in this process is to re-configure the `carts` service to use a DynamoDB table that has already been created for us. The application loads most of its confirmation from a ConfigMap, lets take look at it:

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

The following kustomization overwrites the ConfigMap, removing the DynamoDB endpoint configuration which tells the SDK to default to the real DynamoDB service instead of our test Pod. We've also provided it with the name of the DynamoDB table thats been created already for us which is being pulled from the environment variable `CARTS_DYNAMODB_TABLENAME`.

```kustomization
security/irsa/dynamo/kustomization.yaml
ConfigMap/carts
```

Let's check the value of `CARTS_DYNAMODB_TABLENAME` then run Kustomize to use the real DynamoDB service:

```bash
$ echo $CARTS_DYNAMODB_TABLENAME
eks-workshop-carts
$ kubectl apply -k /workspace/modules/security/irsa/dynamo
```

This will overwrite our ConfigMap with new values:

```bash
$ kubectl get -n carts cm carts -o yaml
apiVersion: v1
data:
  CARTS_DYNAMODB_TABLENAME: eks-workshop
kind: ConfigMap
metadata:
  labels:
    app: carts
  name: carts-dynamo
  namespace: carts
```

Now we need to recycle all the carts Pods to pick up our new ConfigMap contents:

```bash hook=enable-dynamo hookTimeout=430
$ kubectl rollout restart -n carts deployment/carts
deployment.apps/carts restarted
$ kubectl rollout status -n carts deployment/carts
```

Let us try to access our application using the browser. A `LoadBalancer` type service named `ui-nlb` is provisioned in the `ui` namespace from which the application's UI can be accessed.

```bash
$ kubectl get service -n ui ui-nlb -o jsonpath='{.status.loadBalancer.ingress[*].hostname}{"\n"}'
k8s-ui-uinlb-647e781087-6717c5049aa96bd9.elb.us-west-2.amazonaws.com
```
So now our application should be using DynamoDB right? Load it up in the browser using the output of the above command and navigate to the shopping cart:

<browser url="http://k8s-ui-uinlb-647e781087-6717c5049aa96bd9.elb.us-west-2.amazonaws.com/cart">
<img src={require('@site/static/img/sample-app-screens/error-500.png').default}/>
</browser>

The shopping cart page is not accessible! What's gone wrong?
