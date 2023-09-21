---
title: "Implementing Ingress Controls"
sidebar_position: 80
---
<img src={require('@site/static/img/sample-app-screens/architecture.png').default}/>

As shown in the architecture diagram, the 'catalog' namespace receives traffic only from the 'ui' namespace and from no other namespace. Also, the 'catalog' database component can only receive traffic from the 'catalog' service component.

We can start implementing the above network rules using an ingress network policy that will control traffic to the 'catalog' namespace.

Before applying the policy, the 'catalog' service can be accessed by both the 'ui' and 'orders' service components. We can validate this by running the below commands and validating the outputs.

```bash wait=30 timeout=240
$ UI_POD_1=$(kubectl get pod --selector app.kubernetes.io/name=ui -n ui -o json | jq -r '.items[0].metadata.name')
$ echo $UI_POD_1
ui-XXXX-XXX
$ kubectl exec -it ${UI_POD_1} -n ui -- curl -v catalog.catalog/catalogue --connect-timeout 5
   Trying XXX.XXX.XXX.XXX:80...
* Connected to catalog.catalog (XXX.XXX.XXX.XXX) port 80 (#0)
> GET /catalogue HTTP/1.1
> Host: catalog.catalog
> User-Agent: curl/7.88.1
> Accept: */*
> 
< HTTP/1.1 200 OK
...
```
```bash wait=30 timeout=240
$ ORDER_POD_1=$(kubectl get pod --selector app.kubernetes.io/component=service -n orders -o json | jq -r '.items[0].metadata.name')
$ echo $ORDER_POD_1
orders-XXXX-XXX
$ kubectl exec -it ${ORDER_POD_1} -n orders -- curl -v catalog.catalog/catalogue --connect-timeout 5
   Trying XXX.XXX.XXX.XXX:80...
* Connected to catalog.catalog (XXX.XXX.XXX.XXX) port 80 (#0)
> GET /catalogue HTTP/1.1
> Host: catalog.catalog
> User-Agent: curl/7.88.1
> Accept: */*
> 
< HTTP/1.1 200 OK
...
```
Now, we will define a network policy that will allow traffic to the 'catalog' service component only from the 'ui' component.
```file
manifests/modules/networking/network-policies/apply-network-policies/allow-catalog-ingress-webservice.yaml
```
Now, let us apply the policy.
```bash wait=30 timeout=240
$ kubectl apply -f ~/environment/eks-workshop/modules/networking/network-policies/apply-network-policies/allow-catalog-ingress-webservice.yaml
```
Now, we can validate the policy by checking to see if we can connect to the 'catalog' service from the ui' and 'orders' service components.
```bash wait=30 timeout=240
$ UI_POD_1=$(kubectl get pod --selector app.kubernetes.io/name=ui -n ui -o json | jq -r '.items[0].metadata.name')
$ echo $UI_POD_1
ui-XXXX-XXX
$ kubectl exec -it ${UI_POD_1} -n ui -- curl -v catalog.catalog/catalogue --connect-timeout 5
  Trying XXX.XXX.XXX.XXX:80...
* Connected to catalog.catalog (XXX.XXX.XXX.XXX) port 80 (#0)
> GET /catalogue HTTP/1.1
> Host: catalog.catalog
> User-Agent: curl/7.88.1
> Accept: */*
> 
< HTTP/1.1 200 OK
...
```
```bash wait=30 timeout=240
$ ORDER_POD_1=$(kubectl get pod --selector app.kubernetes.io/component=service -n orders -o json | jq -r '.items[0].metadata.name')
$ echo $ORDER_POD_1
orders-XXXX-XXX
$ kubectl exec -it ${ORDER_POD_1} -n orders -- curl -v catalog.catalog/catalogue --connect-timeout 5
*   Trying XXX.XXX.XXX.XXX:80...
* ipv4 connect timeout after 4999ms, move on!
* Failed to connect to catalog.catalog port 80 after 5001 ms: Timeout was reached
* Closing connection 0
curl: (28) Failed to connect to catalog.catalog port 80 after 5001 ms: Timeout was reached
...
```
As you could see from the above outputs, only the 'ui' component is able to communicate with the 'catalog' service component, and the 'orders' service component is not able to.

But this still leaves the 'catalog' database component open, so let us implement a network policy to ensure only the 'catalog' service component alone can communicate with the 'catalog' database component.
```file
manifests/modules/networking/network-policies/apply-network-policies/allow-catalog-ingress-db.yaml
```
```bash wait=30 timeout=240
$ kubectl apply -f ~/environment/eks-workshop/modules/networking/network-policies/apply-network-policies/allow-catalog-ingress-db.yaml
```
Let us validate the network policy.
```bash wait=30 timeout=240
$ ORDER_POD_1=$(kubectl get pod --selector app.kubernetes.io/component=service -n orders -o json | jq -r '.items[0].metadata.name')
$ echo $ORDER_POD_1
orders-XXXX-XXX
$ kubectl exec -it ${ORDER_POD_1} -n orders -- curl -v telnet://catalog-mysql.catalog:3306 --connect-timeout 5
*   Trying XXX.XXX.XXX.XXX:3306...
* ipv4 connect timeout after 4999ms, move on!
* Failed to connect to catalog-mysql.catalog port 3306 after 5001 ms: Timeout was reached
* Closing connection 0
curl: (28) Failed to connect to catalog-mysql.catalog port 3306 after 5001 ms: Timeout was reached
command terminated with exit code 28
...
```
```bash wait=30 timeout=240
$ CATALOG_POD_1=$(kubectl get pod --selector app.kubernetes.io/component=service -n catalog -o json | jq -r '.items[0].metadata.name')
$ echo $CATALOG_POD_1
catalog-XXXX-XXX
$ kubectl exec -it ${CATALOG_POD_1} -n catalog -- curl -v telnet://catalog-mysql.catalog:3306 --connect-timeout 5
*   Trying XXX.XXX.XXX.XXX:3306...
* Connected to catalog-mysql.catalog (XXX.XXX.XXX.XXX) port 3306 (#0)
...
```
As you could see from the above outputs, only the 'catalog' service component alone is able to communicate with the 'catalog' database component.

Now that we have implemented an effective ingress policy for the 'catalog' namespace, we extend the same logic to other namespaces and components in the sample application, thereby greatly reducing the attack surface for the sample application and increasing network security.