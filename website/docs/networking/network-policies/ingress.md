---
title: "Implementing Ingress Controls"
sidebar_position: 80
---
<img src={require('@site/static/img/sample-app-screens/architecture.png').default}/>

As shown in the architecture diagram, the 'checkout' namespace receives traffic only from the 'ui' namespace and from no other namespace. Also, the 'checkout' Redis component can only receive traffic from the 'checkout' service component.

We can start implementing the above network rules using an ingress network policy that will control traffic to the 'checkout' namespace, starting with a default-deny ingress policy.

```file
manifests/modules/networking/network-policies/apply-network-policies/default-deny-ingress.yaml
```

```bash wait=30
$ kubectl apply -n checkout -f ~/environment/eks-workshop/modules/networking/network-policies/apply-network-policies/default-deny-ingress.yaml 
```
>**Note**   : There is no namespace specified in the network policy, as it is a generic policy that can potentially be applied to any namespace in our cluster.

After applying the network policy, all ingress traffic to the 'checkout' namespace will be denied, resulting in an 500-error page when trying to checkout products.

<browser url='http://k8s-ui-albui-634ca3fbcb-1826867757.us-west-2.elb.amazonaws.com/checkout'>
<img src={require('@site/static/img/sample-app-screens/error-500.png').default}/>
</browser>

Now, we'll define a network policy that will allow traffic to the 'checkout' service component only from the 'ui' component:

```file
manifests/modules/networking/network-policies/apply-network-policies/allow-checkout-ingress-webservice.yaml
```

Lets apply the policy:

```bash wait=30
$ kubectl apply -f ~/environment/eks-workshop/modules/networking/network-policies/apply-network-policies/allow-checkout-ingress-webservice.yaml
```

Now, we can validate the policy by confirming that we can select products from the 'catalog' page and checkout them:

<browser url='http://k8s-ui-albui-634ca3fbcb-1826867757.us-west-2.elb.amazonaws.com/checkout'>
<img src={require('@site/static/img/sample-app-screens/error-500.png').default}/>
</browser>

As you could see, we are still getting the error-500 page. This is because the default-deny ingress policy is also blocking calls from the 'checkout' service to 'checkout' Redis cache. So let us allow for calls from 'checkout' service component to the Redis cache.

Now, we'll define a network policy that will allow traffic to the 'checkout' redis component only from the 'checkout' service component:

```file
manifests/modules/networking/network-policies/apply-network-policies/allow-checkout-ingress-redis.yaml
```

Lets apply the policy and restart the 'checkout' pod to ensure proper initialization of the database components:

```bash
$ kubectl get pod -n carts  -l app.kubernetes.io/name=carts -l app.kubernetes.io/component=service -o json | jq -r '.items[].status.podIP'
```

Now, we should be able to checkout one or more products and place an order.

<browser url='http://k8s-ui-albui-634ca3fbcb-1826867757.us-west-2.elb.amazonaws.com/checkout'>
<img src={require('@site/static/img/sample-app-screens/checkout.png').default}/>
</browser>

<browser url='http://k8s-ui-albui-634ca3fbcb-1826867757.us-west-2.elb.amazonaws.com/checkout/payment'>
<img src={require('@site/static/img/sample-app-screens/checkout-order.png').default}/>
</browser>

<browser url='http://k8s-ui-albui-634ca3fbcb-1826867757.us-west-2.elb.amazonaws.com/checkout/confirm'>
<img src={require('@site/static/img/sample-app-screens/order-complete.png').default}/>
</browser>

Now let us do a final validation to ensure that the 'checkout' service component is not accessible to any component other than 'ui' by trying to connect to the 'checkout' service from the 'orders' service component:

```bash expectError=true
$ kubectl exec deployment/orders -n orders -- curl -v checkout.checkout/health --connect-timeout 5
*   Trying XXX.XXX.XXX.XXX:80...
* ipv4 connect timeout after 4999ms, move on!
* Failed to connect to catalog.catalog port 80 after 5001 ms: Timeout was reached
* Closing connection 0
curl: (28) Failed to connect to catalog.catalog port 80 after 5001 ms: Timeout was reached
...
```
As you could see from the above outputs, only the 'ui' component is able to communicate with the 'checkout' service component, and the 'orders' service component is not able to.

Now that we have implemented an effective ingress policy for the 'checkout' namespace, we extend the same logic to other namespaces and components for the sample application, thereby greatly reducing the attack surface for the sample application and increasing network security.