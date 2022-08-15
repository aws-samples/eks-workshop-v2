---
title: Getting started
sidebar_position: 20
---

The workshops use a sample microservices application to demonstrate the various concepts related to EKS.

Use the following command to deploy this sample application:

```bash timeout=300 wait=30
reset-environment
```

## About the application

The sample application models a simple web store application, where customers can browse a catalogue, add items to their cart and complete a purchase.

![UI screenshot](https://github.com/niallthomson/microservices-demo/raw/master/docs/images/screenshot.png)

The application has several components and dependencies:

![Architecture](https://github.com/niallthomson/microservices-demo/raw/master/docs/images/architecture.png)

## Exploring the application

You can start to explore the example application thats been deployed for you. The initial state of the application is that its completely self-contained in the EKS cluster. Each microservice is deployed to its own separate `Namespace` to provide some degree of isolation.

```bash
kubectl get namespaces
```

Most of the components are modeled using the `Deployment` resource in its respective namespace:

```bash
kubectl get deployment -l app.kubernetes.io/created-by=eks-workshop -A
```

All of the `Service` resources are of type `ClusterIP`, which means right now our application cannot be accessed from the outside world. We'll explore exposing the application using various ingress mechanisms in the [Exposing applications](../exposing/) chapter.