---
title: "Traffic Management"
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

Now let's demonstrate how weighted routing works by creating `HTTPRoute` resources. First we'll create a `TargetGroupPolicy` resources so that Lattice knows how to health check our checkout component:

```file
manifests/modules/networking/vpc-lattice/routes/target-group-policy.yaml
```

Apply this resource:

```bash
$ kubectl apply -f ~/environment/eks-workshop/modules/networking/vpc-lattice/routes/target-group-policy.yaml
```

Next create the Kubernetes `HTTPRoute` route that distributes 75% traffic to `checkoutv2` and remaining 25% traffic to `checkout`:

```file
manifests/modules/networking/vpc-lattice/routes/checkout-route.yaml
```

Apply this resource:

```bash hook=route
$ cat ~/environment/eks-workshop/modules/networking/vpc-lattice/routes/checkout-route.yaml \
  | envsubst | kubectl apply -f -
```

This creation of the associated resources may take 2-3 minutes, run the following command to wait for it to complete:

```bash wait=10
$ kubectl wait --for=jsonpath='{.status.parents[-1:].conditions[-1:].reason}'=ResolvedRefs httproute/checkoutroute -n checkout
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

# Check weighted routing is working

In the real world, canary deployments are regularly used to release a feature to a subset of users. In this scenario, we are artifically routing 75% of traffic to the new version of the checkout service. Completing the checkout procedure multiple times with different objects in the cart should present the users with the 2 version of the application.

First lets use Kubernetes `exec` to check that the Lattice service URL works from the UI pod. We'll obtain this from an annotation on the `HTTPRoute` resource:

```bash
$ export CHECKOUT_ROUTE_DNS="http://$(kubectl get httproute checkoutroute -n checkout -o json | jq -r '.metadata.annotations["application-networking.k8s.aws/lattice-assigned-domain-name"]')"
$ POD_NAME=$(kubectl -n ui get pods -o jsonpath='{.items[0].metadata.name}')
$ kubectl exec $POD_NAME -n ui -- curl -s $CHECKOUT_ROUTE_DNS/health
{"status":"ok","info":{},"error":{},"details":{}}
$ echo "DNS WAS $CHECKOUT_ROUTE_DNS"
```

Now we have to point the UI service to the VPC Lattice service endpoint by patching the `ConfigMap` for the UI component:

```kustomization
modules/networking/vpc-lattice/ui/configmap.yaml
ConfigMap/ui
```

Make this configuration change:

```bash
$ echo "DNS IS $CHECKOUT_ROUTE_DNS"
$ kustomize build ~/environment/eks-workshop/modules/networking/vpc-lattice/ui/ \
  | envsubst | kubectl apply -f -
```

Let's ensure that the UI pods are restarted and then port-forward to the preview of your application with Cloud9.

```bash
$ kubectl rollout restart deployment/ui -n ui
$ kubectl rollout status deployment/ui -n ui
```

Let us try to access our application using the browser. A `LoadBalancer` type service named `ui-nlb` is provisioned in the `ui` namespace from which the application's UI can be accessed.

```bash
$ kubectl get service -n ui ui-nlb -o jsonpath='{.status.loadBalancer.ingress[*].hostname}{"\n"}'
k8s-ui-uinlb-647e781087-6717c5049aa96bd9.elb.us-west-2.amazonaws.com
```

Access this in your browser and try to checkout multiple times (with different items in the cart):

![Example Checkout](assets/examplecheckout.png)

You'll notice that the checkout now uses the "Lattice checkout" pods about 75% of the time:

![Lattice Checkout](assets/latticecheckout.png)