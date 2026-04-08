---
title: "Testing traffic routing"
sidebar_position: 40
---

In the real world, canary deployments are regularly used to release a feature to a subset of users. In this scenario, we are artificially routing 75% of traffic to the new version of the checkout service. Completing the checkout procedure multiple times with different objects in the cart should present the users with the 2 version of the application.

First lets use Kubernetes `exec` to check that the Lattice service URL works from the UI pod. We'll obtain this from an annotation on the `HTTPRoute` resource:

```bash
$ export CHECKOUT_ROUTE_DNS="http://$(kubectl get httproute checkoutroute -n checkout -o json | jq -r '.metadata.annotations["application-networking.k8s.aws/lattice-assigned-domain-name"]')"
$ echo "Checkout Lattice DNS is $CHECKOUT_ROUTE_DNS"
$ POD_NAME=$(kubectl -n ui get pods -o jsonpath='{.items[0].metadata.name}')
$ kubectl exec $POD_NAME -n ui -- curl -s $CHECKOUT_ROUTE_DNS/health
{"status":"ok","info":{},"error":{},"details":{}}
```

Now we have to point the UI service to the VPC Lattice service endpoint by patching the `ConfigMap` for the UI component:

```kustomization
modules/networking/vpc-lattice/ui/configmap.yaml
ConfigMap/ui
```

Make this configuration change:

```bash
$ kubectl kustomize ~/environment/eks-workshop/modules/networking/vpc-lattice/ui/ \
  | envsubst | kubectl apply -f -
```

Now restart the UI component pods:

```bash
$ kubectl rollout restart deployment/ui -n ui
$ kubectl rollout status deployment/ui -n ui
```

Lets try to access our application using the browser. A `LoadBalancer` type service named `ui-nlb` is provisioned in the `ui` namespace from which the application's UI can be accessed.

```bash
$ kubectl get service -n ui ui-nlb -o jsonpath='{.status.loadBalancer.ingress[*].hostname}{"\n"}'
k8s-ui-uinlb-647e781087-6717c5049aa96bd9.elb.us-west-2.amazonaws.com
```

Access this in your browser and try to checkout multiple times (with different items in the cart):

![Example Checkout](/docs/networking/vpc-lattice/examplecheckout.webp)

You'll notice that the checkout now uses the "Lattice checkout" pods about 75% of the time:

![Lattice Checkout](/docs/networking/vpc-lattice/latticecheckout.webp)
