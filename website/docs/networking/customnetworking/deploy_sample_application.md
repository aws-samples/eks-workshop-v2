---
title: "Deploy a sample application"
sidebar_position: 25
weight: 50
---

Lets deploy a sample application to test the “custom networking” updates we have made so far. This sample application models a simple web store application, where customer can browse a catalogue, add items to their cart and complete a purchase.

```bash expectError=true
$ kubectl apply -k ./environment/workspace/manifests
```

Explore the application

You can start to explore the example application thats been deployed for you. The initial state of the application is that its completely self-contained in the EKS cluster. Each microservice is deployed to its own separate Namespace to provide some degree of isolation.

```bash expectError=true
$ kubectl get namespaces -l app.kubernetes.io/created-by=eks-workshop
```

Lets review the microservices deployed in the “orders” namespace.

```bash expectError=true
$ kubectl get pods -n orders -o wide
```

Here is a sample output from the previous command

```bash expectError=true
$ kubectl get pods -n orders -o wide
NAME                            READY   STATUS    RESTARTS      AGE   IP              NODE                                          NOMINATED NODE   READINESS GATES
orders-59b94995cf-ppx6q         1/1     Running   1 (65s ago)   88s   100.64.11.17    ip-10-42-11-6.us-west-2.compute.internal      <none>           <none>
orders-mysql-749f67f7d4-nh8gm   1/1     Running   0             88s   100.64.10.160   ip-100-64-10-224.us-west-2.compute.internal   <none>           <none>
```