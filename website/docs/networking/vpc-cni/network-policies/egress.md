---
title: "Implementing Egress Controls"
sidebar_position: 70
---
<img src={require('@site/static/img/sample-app-screens/architecture.png').default}/>

As shown in the above architecture diagram, the 'ui' component is the front-facing app. So we can start implementing our network controls for the 'ui' component by defining a network policy that will block all egress traffic from the 'ui' namespace.

```file
manifests/modules/networking/network-policies/apply-network-policies/default-deny.yaml
```

>**Note**   : There is no namespace specified in the network policy, as it is a generic policy that can potentially be applied to any namespace in our cluster.

```bash wait=30
$ kubectl apply -n ui -f ~/environment/eks-workshop/modules/networking/network-policies/apply-network-policies/default-deny.yaml 
networkpolicy.networking.k8s.io/default-deny created
```

Now let us try accessing the application. You should get a 500-error page.

<browser url='http://k8s-ui-albui-634ca3fbcb-952136118.us-west-2.elb.amazonaws.com/home'>
<img src={require('@site/static/img/sample-app-screens/error-500.png').default}/>
</browser>

Implementing the above policy will result in the sample application no longer working. This is because the 'ui' component requires access to the 'catalog' service and other service components, and the default-deny policy we implemented blocks all calls to those service components. To define an effective egress policy for the 'ui' component requires understanding the network dependencies for the component.

In the case of the 'ui' component, it needs to communicate with all the other service components, such as 'catalog', 'orders, etc. Apart from this, 'ui' will also need to be able to communicate with components in the cluster system namespaces. For example, for the 'ui' component to work, it needs to be able to perform DNS lookups, which requires it to communicate with the CoreDNS service in the 'kube-system' namespace.

The below network policy was designed considering the above requirements. It has two key sections:

* The first section focuses on allowing egress traffic to all service components, such as 'catalog', 'orders', etc., which means allowing egress traffic to any namespace as long as the pod labels match "app.kubernetes.io/component: service".
* The second section focuses on allowing egress traffic to all components in the kube-system namespace, which enables DNS lookups and other key communications with the components in the system namespace.

```file
manifests/modules/networking/network-policies/apply-network-policies/allow-ui-egress.yaml
```

Lets apply this additional policy:

```bash wait=30
$ kubectl apply -f ~/environment/eks-workshop/modules/networking/network-policies/apply-network-policies/allow-ui-egress.yaml
networkpolicy.networking.k8s.io/allow-ui-egress created
```

Now, we can test to see if we are able to view the 'catalog' page of the sample application:

<browser url='http://k8s-ui-albui-634ca3fbcb-1826867757.us-west-2.elb.amazonaws.com/catalog'>
<img src={require('@site/static/img/sample-app-screens/catalog.png').default}/>
</browser>

As you could see from your browser, the sample application is now working, and you can access the 'catalog' page of the application.

Similarly, we can test to see if we are able to access to other pages like the 'cart' page, which we should be able to. 

<browser url='http://k8s-ui-albui-634ca3fbcb-1826867757.us-west-2.elb.amazonaws.com/cart'>
<img src={require('@site/static/img/sample-app-screens/cart.png').default}/>
</browser>

However, any calls to the internet or other third-party services from the 'ui' namespace should be blocked. Let us see if we are able to access 'www.google.com' from the 'ui' pod.

```bash expectError=true
$ kubectl exec deployment/ui -n ui -- curl -v www.google.com --connect-timeout 5
   Trying XXX.XXX.XXX.XXX:80...
*   Trying [XXXX:XXXX:XXXX:XXXX::XXXX]:80...
* Immediate connect fail for XXXX:XXXX:XXXX:XXXX::XXXX: Network is unreachable
curl: (28) Failed to connect to www.google.com port 80 after 5001 ms: Timeout was reached
command terminated with exit code 28
```

Now that we have defined an effective egress policy for 'ui' component, let us focus on the 'checkout' service and database components to implement a network policy to control ingress traffic to the 'checkout' namespace.