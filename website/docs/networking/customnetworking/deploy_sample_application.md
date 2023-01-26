---
title: "Re-deploy workload"
sidebar_position: 25
---

In order to test the custom networking updates we have made so far, lets update the `checkout` deployment to run the pods in the new node we provisioned in the previous step.

To make the change, run the following command to modify the `checkout` deployment in your cluster

```bash timeout=240
$ kubectl apply -k /workspace/modules/networking/custom-networking/sampleapp
$ kubectl rollout status deployment/checkout -n checkout --timeout 180s
```

The command adds a `nodeSelector` to the `checkout` deployment.

```kustomization
networking/custom-networking/sampleapp/checkout.yaml
Deployment/checkout
```

Let's review the microservices deployed in the “checkout” namespace.

```bash
$ kubectl get pods -n checkout -o wide
NAME                              READY   STATUS    RESTARTS   AGE   IP             NODE                                         NOMINATED NODE   READINESS GATES
checkout-5fbbc99bb7-brn2m         1/1     Running   0          98s   100.64.10.16   ip-10-42-10-14.us-west-2.compute.internal    <none>           <none>
checkout-redis-6cfd7d8787-8n99n   1/1     Running   0          49m   10.42.12.33    ip-10-42-12-155.us-west-2.compute.internal   <none>           <none>
```

You can see that the `checkout` pod is assigned an IP address from the `100.64.0.0` CIDR block that was added to the VPC. Pods that have not yet been redeployed are still assigned addresses from the `10.42.0.0` CIDR block, because it was the only CIDR block originally associated with the VPC. In this example, the `checkout-redis` pod still has an address from this range.
