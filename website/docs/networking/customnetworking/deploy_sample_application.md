---
title: "Deploy a sample application"
sidebar_position: 25
weight: 50
---

In order to test the custom networking updates we have made so far, lets update the checkout deployment to run the pods in the new node we provisioned in the previous step.

To make the change, run the following command to modify the **checkout** deployment in your cluster
```bash
$ kubectl apply -k /workspace/modules/networking/custom-networking/
```
The command adds a `nodeSelector` to the **checkout** deployment.
```kustomization
networking/custom-networking/checkout.yaml
Deployment/checkout
```

Lets review the microservices deployed in the “checkout” namespace.

```bash expectError=true
$ kubectl get pods -n checkout -o wide
```

Here is a sample output from the previous command

```bash expectError=true
$ kubectl get pods -n orders -o wide
NAME                              READY   STATUS    RESTARTS   AGE   IP              NODE                                         NOMINATED NODE   READINESS GATES
checkout-5fbbc99bb7-lgv78         1/1     Running   0          75s   100.64.10.34    ip-10-42-10-127.us-west-2.compute.internal   <none>           <none>
checkout-redis-6cfd7d8787-vhbgp   1/1     Running   0          16m   100.64.11.113   ip-10-42-11-189.us-west-2.compute.internal   <none>           <none>
```