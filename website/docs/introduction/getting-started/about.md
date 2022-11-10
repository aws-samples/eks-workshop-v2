---
title: Exploring
sidebar_position: 20
---

The sample application models a simple web store application, where customers can browse a catalogue, add items to their cart and complete a purchase.

<browser url="-">
<img src="https://github.com/niallthomson/microservices-demo/raw/master/docs/images/screenshot.png"/>
</browser>

The application has several components and dependencies:

![Architecture](https://github.com/niallthomson/microservices-demo/raw/master/docs/images/architecture.png)

You can start to explore the example application thats been deployed for you. The initial state of the application is that its completely self-contained in the EKS cluster. Each microservice is deployed to its own separate `Namespace` to provide some degree of isolation.

```bash
$ kubectl get namespaces -l app.kubernetes.io/created-by=eks-workshop
NAME       STATUS   AGE
activemq   Active   5h6m
assets     Active   5h6m
carts      Active   5h6m
catalog    Active   5h6m
checkout   Active   5h6m
orders     Active   5h6m
other      Active   5h6m
ui         Active   5h6m
```

Most of the components are modeled using the `Deployment` resource in its respective namespace:

```bash
$ kubectl get deployment -l app.kubernetes.io/created-by=eks-workshop -A
NAMESPACE   NAME             READY   UP-TO-DATE   AVAILABLE   AGE
assets      assets           1/1     1            1           5h6m
carts       carts            1/1     1            1           5h6m
carts       carts-dynamodb   1/1     1            1           5h6m
catalog     catalog          1/1     1            1           5h6m
catalog     catalog-mysql    1/1     1            1           5h6m
checkout    checkout         1/1     1            1           5h6m
checkout    checkout-redis   1/1     1            1           5h6m
orders      orders           1/1     1            1           5h6m
orders      orders-mysql     1/1     1            1           5h6m
ui          ui               1/1     1            1           5h6m
```

All of the `Service` resources are of type `ClusterIP`, which means right now our application cannot be accessed from the outside world. We'll explore exposing the application using various ingress mechanisms later in the labs.
