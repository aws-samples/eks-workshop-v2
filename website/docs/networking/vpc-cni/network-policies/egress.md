---
title: "Implementing Egress Controls"
sidebar_position: 70
---

<img src={require('@site/static/img/sample-app-screens/architecture.webp').default}/>

As shown in the above architecture diagram, the 'ui' component is the front-facing app. So we can start implementing our network controls for the 'ui' component by defining a network policy that will block all egress traffic from the 'ui' namespace.

::yaml{file="manifests/modules/networking/network-policies/apply-network-policies/default-deny.yaml" paths="spec.podSelector,spec.policyTypes"}

1. The empty selector `{}` matches all pods
2. The `Egress` policy type controls outbound traffic from pods

> **Note** : There is no namespace specified in the network policy, as it is a generic policy that can potentially be applied to any namespace in our cluster.

```bash wait=30
$ kubectl apply -n ui -f ~/environment/eks-workshop/modules/networking/network-policies/apply-network-policies/default-deny.yaml
```

Now let us try accessing the 'catalog' component from the 'ui' component,

```bash expectError=true
$ kubectl exec deployment/ui -n ui -- curl -s http://catalog.catalog/health --connect-timeout 5
command terminated with exit code 28
```

On execution of the curl command, the output displayed should have the below statement, which shows that the 'ui' component now cannot directly communicate with the 'catalog' component.

```text
command terminated with exit code 28
```

Implementing the above policy will also cause the sample application to no longer function properly as 'ui' component requires access to the 'catalog' service and other service components. To define an effective egress policy for 'ui' component requires understanding the network dependencies for the component.

In the case of the 'ui' component, it needs to communicate with all the other service components, such as 'catalog', 'orders, etc. Apart from this, 'ui' will also need to be able to communicate with components in the cluster system namespaces. For example, for the 'ui' component to work, it needs to be able to perform DNS lookups, which requires it to communicate with the CoreDNS service in the `kube-system` namespace.

The network policy below was designed with the above requirements in mind.

::yaml{file="manifests/modules/networking/network-policies/apply-network-policies/allow-ui-egress.yaml" paths="spec.egress.0.to.0,spec.egress.0.to.1"}

1. The first egress rule focuses on allowing egress traffic to all `service` components such as 'catalog', 'orders' etc. (without providing access to the database components), along with the `namespaceSelector` which allows for egress traffic to any namespace as long as the pod labels match `app.kubernetes.io/component: service`
2. The second egress rule focuses on allowing egress traffic to all components in the `kube-system` namespace, which enables DNS lookups and other key communications with the components in the system namespace

Lets apply this additional policy:

```bash wait=30
$ kubectl apply -f ~/environment/eks-workshop/modules/networking/network-policies/apply-network-policies/allow-ui-egress.yaml
```

Now, we can test to see if we can connect to 'catalog' service:

```bash
$ kubectl exec deployment/ui -n ui -- curl http://catalog.catalog/health
OK
```

As you can see from the outputs, we can now connect to the 'catalog' service but not the database since it does not have the `app.kubernetes.io/component: service` label:

```bash expectError=true
$ kubectl exec deployment/ui -n ui -- curl -v telnet://catalog-mysql.catalog:3306 --connect-timeout 5
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
  0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0* Host catalog-mysql.catalog:3306 was resolved.
* IPv6: (none)
* IPv4: 172.16.244.252
*   Trying 172.16.244.252:3306...
  0     0    0     0    0     0      0      0 --:--:--  0:00:04 --:--:--     0* Connection timed out after 5002 milliseconds
  0     0    0     0    0     0      0      0 --:--:--  0:00:05 --:--:--     0
* closing connection #0
curl: (28) Connection timed out after 5002 milliseconds
command terminated with exit code 28
```

Similarly, we can test to see if we are able to connect to other services like the 'order' service, which we should be able to. However, any calls to the internet or other third-party services should be blocked.

```bash expectError=true
$ kubectl exec deployment/ui -n ui -- curl -v www.google.com --connect-timeout 5
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
  0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0* Host www.google.com:80 was resolved.
* IPv6: 2001:4860:482a:7700::, 2001:4860:482d:7700::, 2001:4860:4828:7700::, 2001:4860:4826:7700::, 2001:4860:482c:7700::, 2001:4860:4827:7700::, 2001:4860:482b:7700::, 2001:4860:4829:7700::
* IPv4: 142.251.157.119, 142.251.152.119, 142.251.155.119, 142.251.156.119, 142.251.154.119, 142.251.150.119, 142.251.153.119, 142.251.151.119
*   Trying [2001:4860:482a:7700::]:80...
* Immediate connect fail for 2001:4860:482a:7700::: Network is unreachable
*   Trying [2001:4860:482d:7700::]:80...
* Immediate connect fail for 2001:4860:482d:7700::: Network is unreachable
...
...
*   Trying [2001:4860:4829:7700::]:80...
* Immediate connect fail for 2001:4860:4829:7700::: Network is unreachable
*   Trying 142.251.157.119:80...
  0     0    0     0    0     0      0      0 --:--:--  0:00:02 --:--:--     0* ipv4 connect timeout after 2497ms, move on!
  0     0    0     0    0     0      0      0 --:--:--  0:00:02 --:--:--     0*   Trying 142.251.152.119:80...
  0     0    0     0    0     0      0      0 --:--:--  0:00:03 --:--:--     0* ipv4 connect timeout after 1247ms, move on!
*   Trying 142.251.155.119:80...
* ipv4 connect timeout after 623ms, move on!
*   Trying 142.251.156.119:80...
* ipv4 connect timeout after 312ms, move on!
  0     0    0     0    0     0      0      0 --:--:--  0:00:04 --:--:--     0*   Trying 142.251.154.119:80...
* Connection timed out after 5001 milliseconds
  0     0    0     0    0     0      0      0 --:--:--  0:00:05 --:--:--     0
* closing connection #0
curl: (28) Connection timed out after 5001 milliseconds
command terminated with exit code 28
```

Now that we have defined an effective egress policy for 'ui' component, let us focus on the catalog service and database components to implement a network policy to control traffic to the 'catalog' namespace.
