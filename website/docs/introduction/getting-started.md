---
title: Getting started
sidebar_position: 20
---

The workshop modules use a sample microservices application to demonstrate the various concepts related to EKS.

## About the application

The sample application models a simple web store application, where customers can browse a catalogue, add items to their cart and complete a purchase.

![UI screenshot](https://github.com/niallthomson/microservices-demo/raw/master/docs/images/screenshot.png)

The application has several components and dependencies:

![Architecture](https://github.com/niallthomson/microservices-demo/raw/master/docs/images/architecture.png)

## Deploying the application

The sample application is composed of a set of Kubernetes manifests organized in a way that can be easily applied with Kustomize. This allows us to not only make the manifests easier to break apart and navigate, but also incrementally apply overlays and patches as we work through the various modules of this workshop.

If you want to understand more about Kustomize take a look at the [optional module](./kustomize.md) provided in this workshop.

There are different ways you can browse the manifests for the sample application depending on your comfort level. One way is to take a look at the GitHub repository for this workshop:

  [https://github.com/aws-samples/eks-workshop-v2/tree/main/environment/workspace/manifests](https://github.com/aws-samples/eks-workshop-v2/tree/main/environment/workspace/manifests)

Alternatively you can explore the manifests directly in your workshop environment. For example, use the `tree` command to visualize the directory structure:

```bash
tree --dirsfirst /workspace/manifests
|-- activemq
|   |-- configMap.yaml
|   |-- kustomization.yaml
|   |-- namespace.yaml
|   |-- service.yaml
|   |-- serviceAccount.yaml
|   `-- statefulSet.yaml
|-- assets
|   |-- configMap.yaml
|   |-- deployment.yaml
|   |-- kustomization.yaml
|   |-- namespace.yaml
|   |-- service.yaml
|   `-- serviceAccount.yaml
|-- carts
|   |-- configMap.yaml
|   |-- deployment-db.yaml
|   |-- deployment.yaml
|   |-- kustomization.yaml
|   |-- namespace.yaml
|   |-- service-db.yaml
|   |-- service.yaml
|   `-- serviceAccount.yaml
|-- catalog
|   |-- configMap.yaml
|   |-- deployment-mysql.yaml
|   |-- deployment.yaml
|   |-- kustomization.yaml
|   |-- namespace.yaml
|   |-- secrets.yaml
|   |-- service-mysql.yaml
|   |-- service.yaml
|   `-- serviceAccount.yaml
|-- checkout
|   |-- configMap.yaml
|   |-- deployment-redis.yaml
|   |-- deployment.yaml
|   |-- kustomization.yaml
|   |-- namespace.yaml
|   |-- service-redis.yaml
|   |-- service.yaml
|   `-- serviceAccount.yaml
|-- orders
|   |-- configMap.yaml
|   |-- deployment-mysql.yaml
|   |-- deployment.yaml
|   |-- kustomization.yaml
|   |-- namespace.yaml
|   |-- secrets.yaml
|   |-- service-mysql.yaml
|   |-- service.yaml
|   `-- serviceAccount.yaml
|-- other
|   |-- configMap.yaml
|   |-- kustomization.yaml
|   `-- namespace.yaml
|-- ui
|   |-- configMap.yaml
|   |-- deployment.yaml
|   |-- kustomization.yaml
|   |-- namespace.yaml
|   |-- service.yaml
|   `-- serviceAccount.yaml
`-- kustomization.yaml
```

To deploy the application, run the following `kubectl` command:

```bash timeout=300 wait=30
kubectl apply -k /workspace/manifests
```

## Exploring the application

You can start to explore the example application thats been deployed for you. The initial state of the application is that its completely self-contained in the EKS cluster. Each microservice is deployed to its own separate `Namespace` to provide some degree of isolation.

```bash
kubectl get namespaces -l app.kubernetes.io/created-by=eks-workshop
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
kubectl get deployment -l app.kubernetes.io/created-by=eks-workshop -A
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

All of the `Service` resources are of type `ClusterIP`, which means right now our application cannot be accessed from the outside world. We'll explore exposing the application using various ingress mechanisms in the [Exposing applications](../exposing/) chapter.
