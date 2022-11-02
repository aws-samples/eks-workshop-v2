---
title: "Deploy a sample application"
sidebar_position: 5
weight: 50
---

Lets deploy a sample application to test the “custom networking” updates we have made so far. This sample application models a simple web store application, where customer can browse a catalogue, add items to their cart and complete a purchase.

```bash expectError=true
kubectl apply -k ./environment/workspace/manifests
```

TODO - Validate path with event engine.

Explore the application

You can start to explore the example application thats been deployed for you. The initial state of the application is that its completely self-contained in the EKS cluster. Each microservice is deployed to its own separate Namespace to provide some degree of isolation.

```bash expectError=true
kubectl get namespaces -l app.kubernetes.io/created-by=eks-workshop
```

TODO - Add kubectl output

Lets review the microservices deployed in the “orders” namespace.

```bash expectError=true
kubectl get all -n orders
kubectl get pods -n orders -o wide
```

TODO - Add kubectl output