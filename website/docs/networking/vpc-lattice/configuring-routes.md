---
title: "Configuring routes"
sidebar_position: 30
---

In this section we will show how to use Amazon VPC Lattice for advanced traffic management with weighted routing for blue/green and canary-style deployments.

Let's deploy a modified version of the `checkout` microservice with an added prefix *"Lattice"* in the shipping options. Let's deploy this new version in a new namespace (`checkoutv2`) using Kustomize.

```bash
$ kubectl apply -k ~/environment/eks-workshop/modules/networking/vpc-lattice/abtesting/
$ kubectl rollout status deployment/checkout -n checkoutv2
```

The `checkoutv2` namespace now contains a second version of the application, while using the same `redis` instance in the `checkout` namespace.

```bash
$ kubectl get pods -n checkoutv2
NAME                        READY   STATUS    RESTARTS   AGE
checkout-854cd7cd66-s2blp   1/1     Running   0          26s
```

Now let's demonstrate how weighted routing works by creating `HTTPRoute` resources. First we'll create a `TargetGroupPolicy` that tells Lattice how to properly perform health checks on our checkout service:

```file
manifests/modules/networking/vpc-lattice/target-group-policy/target-group-policy.yaml
```

Apply this resource:

```bash wait=10
$ kubectl apply -k ~/environment/eks-workshop/modules/networking/vpc-lattice/target-group-policy
```

Now create the Kubernetes `HTTPRoute` route that distributes 75% traffic to `checkoutv2` and remaining 25% traffic to `checkout`:

```file
manifests/modules/networking/vpc-lattice/routes/checkout-route.yaml
```

Apply this resource:

```bash hook=route
$ cat ~/environment/eks-workshop/modules/networking/vpc-lattice/routes/checkout-route.yaml \
  | envsubst | kubectl apply -f -
```

This creation of the associated resources may take 2-3 minutes, run the following command to wait for it to complete:

```bash wait=10 timeout=400
$ kubectl wait -n checkout --timeout=3m \
  --for=jsonpath='{.status.parents[-1:].conditions[-1:].reason}'=ResolvedRefs httproute/checkoutroute
```

Once completed you will find the `HTTPRoute`'s DNS name from `HTTPRoute` status (highlighted here on the `message` line):

```bash
$ kubectl describe httproute checkoutroute -n checkout
Name:         checkoutroute
Namespace:    checkout
Labels:       <none>
Annotations:  application-networking.k8s.aws/lattice-assigned-domain-name:
                checkoutroute-checkout-0d8e3f4604a069e36.7d67968.vpc-lattice-svcs.us-east-2.on.aws
API Version:  gateway.networking.k8s.io/v1beta1
Kind:         HTTPRoute
...
Status:
  Parents:
    Conditions:
      Last Transition Time:  2023-06-12T16:42:08Z
      Message:               DNS Name: checkoutroute-checkout-0d8e3f4604a069e36.7d67968.vpc-lattice-svcs.us-east-2.on.aws
      Reason:                ResolvedRefs
      Status:                True
      Type:                  ResolvedRefs
...
```

 Now you can see the associated Service created in the [VPC Lattice console](https://console.aws.amazon.com/vpc/home#Services) under the Lattice resources.
![CheckoutRoute Service](assets/checkoutroute.png)

:::tip Traffic is now handled by Amazon VPC Lattice
Amazon VPC Lattice can now automatically redirect traffic to this service from any source, including different VPCs! You can also take full advantage of other VPC Lattice [features](https://aws.amazon.com/vpc/lattice/features/).
:::