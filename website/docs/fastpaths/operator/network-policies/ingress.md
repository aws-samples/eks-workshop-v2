---
title: "Implementing Ingress Controls"
sidebar_position: 80
---

<img src={require('@site/static/img/sample-app-screens/architecture.webp').default}/>

As shown in the architecture diagram, the 'catalog' namespace receives traffic only from the 'ui' namespace and from no other namespace. Also, the 'catalog' database component can only receive traffic from the 'catalog' service component.

We can start implementing the above network rules using an ingress network policy that will control traffic to the 'catalog' namespace.

Before applying the policy, the 'catalog' service can be accessed by both the 'ui' component:

```bash
$ kubectl exec deployment/ui -n ui -- curl -v catalog.catalog/health --connect-timeout 5
   Trying XXX.XXX.XXX.XXX:80...
* Connected to catalog.catalog (XXX.XXX.XXX.XXX) port 80 (#0)
> GET /health HTTP/1.1
> Host: catalog.catalog
> User-Agent: curl/7.88.1
> Accept: */*
>
< HTTP/1.1 200 OK
...
```

As well as the 'orders' component:

```bash
$ kubectl exec deployment/orders -n orders -- curl -v catalog.catalog/health --connect-timeout 5
   Trying XXX.XXX.XXX.XXX:80...
* Connected to catalog.catalog (XXX.XXX.XXX.XXX) port 80 (#0)
> GET /health HTTP/1.1
> Host: catalog.catalog
> User-Agent: curl/7.88.1
> Accept: */*
>
< HTTP/1.1 200 OK
...
```

Now, we'll define a network policy that will allow traffic to the 'catalog' service component only from the 'ui' component:

::yaml{file="manifests/modules/networking/network-policies/apply-network-policies/allow-catalog-ingress-webservice.yaml" paths="spec.podSelector,spec.ingress.0.from.0"}

1. The `podSelector` targets pods with labels `app.kubernetes.io/name: catalog` and `app.kubernetes.io/component: service`
2. This `ingress.from` configuration allows inbound connections only from pods running in the `ui` namespace identified by `kubernetes.io/metadata.name: ui` with label `app.kubernetes.io/name: ui` 

Let's apply the policy:

```bash wait=30
$ kubectl apply -f ~/environment/eks-workshop/modules/networking/network-policies/apply-network-policies/allow-catalog-ingress-webservice.yaml
```

Now, we can validate the policy by confirming that we can still access the 'catalog' component from the 'ui':

```bash
$ kubectl exec deployment/ui -n ui -- curl -v catalog.catalog/health --connect-timeout 5
  Trying XXX.XXX.XXX.XXX:80...
* Connected to catalog.catalog (XXX.XXX.XXX.XXX) port 80 (#0)
> GET /health HTTP/1.1
> Host: catalog.catalog
> User-Agent: curl/7.88.1
> Accept: */*
>
< HTTP/1.1 200 OK
...
```

But not from the 'orders' component:

```bash expectError=true
$ kubectl exec deployment/orders -n orders -- curl -v catalog.catalog/health --connect-timeout 5
*   Trying XXX.XXX.XXX.XXX:80...
* ipv4 connect timeout after 4999ms, move on!
* Failed to connect to catalog.catalog port 80 after 5001 ms: Timeout was reached
* Closing connection 0
curl: (28) Failed to connect to catalog.catalog port 80 after 5001 ms: Timeout was reached
...
```

As you could see from the above outputs, only the 'ui' component is able to communicate with the 'catalog' service component, and the 'orders' service component is not able to.

But this still leaves the 'catalog' database component open, so let us implement a network policy to ensure only the 'catalog' service component can communicate with the 'catalog' database component.

::yaml{file="manifests/modules/networking/network-policies/apply-network-policies/allow-catalog-ingress-db.yaml" paths="spec.podSelector,spec.ingress.0.from.0"}

1. The `podSelector` targets pods with labels `app.kubernetes.io/name: catalog` and `app.kubernetes.io/component: mysql`
2. The `ingress.from` allows inbound connections only from pods with labels `app.kubernetes.io/name: catalog` and `app.kubernetes.io/component: service`

Lets apply the policy:

```bash wait=30
$ kubectl apply -f ~/environment/eks-workshop/modules/networking/network-policies/apply-network-policies/allow-catalog-ingress-db.yaml
```

Let us validate the network policy by confirming we cannot connect to the 'catalog' database from the 'orders' component:

```bash expectError=true
$ kubectl exec deployment/orders -n orders -- curl -v catalog-mysql.catalog:3306 --connect-timeout 5
*   Trying XXX.XXX.XXX.XXX:3306...
* ipv4 connect timeout after 4999ms, move on!
* Failed to connect to catalog-mysql.catalog port 3306 after 5001 ms: Timeout was reached
* Closing connection 0
curl: (28) Failed to connect to catalog-mysql.catalog port 3306 after 5001 ms: Timeout was reached
command terminated with exit code 28
...
```

It's important to note, that the Network Policy doesn't rely on IP address. You can play with restarting the 'catalog' pod and confirms that you can still connect:

```bash
$ kubectl rollout restart deployment/catalog -n catalog
$ kubectl rollout status deployment/catalog -n catalog --timeout=2m
```

Now, let's check if we can connect to the 'catalog-mysql' database from a 'catalog' pod. 

```bash
$ kubectl exec deployment/catalog -n catalog -- curl -v catalog-mysql.catalog:3306 --connect-timeout 5 --http0.9
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
  0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0* Host catalog-mysql.catalog:3306 was resolved.
* IPv6: (none)
* IPv4: 172.20.233.240
*   Trying 172.20.233.240:3306...
* Connected to catalog-mysql.catalog (172.20.233.240) port 3306
* using HTTP/1.x
> GET / HTTP/1.1
> Host: catalog-mysql.catalog:3306
> User-Agent: curl/8.11.1
> Accept: */*
> 
* Request completely sent off
{ [5 bytes data]
100   115    0   115    0     0  20901      0 --:--:-- --:--:-- --:--:-- 23000
* shutting down connection #0
```

As you could see from the above outputs, only the 'catalog' service component alone is able to communicate with the 'catalog' database component.

Now that we have implemented an effective ingress policy for the 'catalog' namespace, we extend the same logic to other namespaces and components in the sample application, thereby greatly reducing the attack surface for the sample application and increasing network security. 
