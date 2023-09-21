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

```bash wait=30 timeout=240
$ kubectl apply -n ui -f ~/environment/eks-workshop/modules/networking/network-policies/apply-network-policies/default-deny.yaml 
```
Now let us try accessing the 'catalog' database from tbe 'ui' component,
```bash wait=30 timeout=240
$ UI_POD_1=$(kubectl get pod --selector app.kubernetes.io/name=ui -n ui -o json | jq -r '.items[0].metadata.name')
$ echo $UI_POD_1
ui-XXXX-XXX
$ kubectl exec -it ${UI_POD_1} -n ui -- curl -v telnet://catalog-mysql.catalog:3306 --connect-timeout 5
 Resolving timed out after 5000 milliseconds
* Closing connection 0
curl: (28) Resolving timed out after 5000 milliseconds
...
```
On execution of the curl statement, the output displayed should have the below statement, which shows that the 'ui' component now cannot directly communicate with the 'catalog' database component.
```
curl: (28) Resolving timed out after 5000 milliseconds
```
Implementing the above policy will also cause the sample application to no longer function properly as 'ui' component requires access to the 'catalog' service and other service components. To define an effective egress policy for 'ui' component requires understanding the network dependencies for the component.

In the case of the 'ui' component, it needs to communicate with all the other service components, such as 'catalog', 'orders, etc. Apart from this, 'ui' will also need to be able to communicate with components in the cluster system namespaces. For example, for the 'ui' component to work, it needs to be able to perform DNS lookups, which requires it to communicate with the CoreDNS service in the 'kube-system' namespace.

The below network policy was designed considering the above requirements. It has two key sections:
* The first section focuses on allowing egress traffic to all service components such as 'catalog', 'orders' etc. without providing access to the database components through a combination of namespaceSelector, which allows for egress traffic to any namespace as long as the pod labels match "app.kubernetes.io/component: service".
* The second section focuses on allowing egress traffic to all components in the kube-system namespace, which enables DNS lookups and other key communications with the components in the system namespace.
```file
manifests/modules/networking/network-policies/apply-network-policies/allow-ui-egress.yaml
```

Before we apply the new policy, we have to delete the 'deny' policy and then apply the new policy.
```bash wait=30 timeout=240
$ kubectl delete -n ui -f ~/environment/eks-workshop/modules/networking/network-policies/apply-network-policies/default-deny.yaml 
$ kubectl apply -f ~/environment/eks-workshop/modules/networking/network-policies/apply-network-policies/allow-ui-egress.yaml
```
Now, we can test to see if we are able to connect to 'catlog' service but not the 'catalog' database
```bash wait=30 timeout=240
$ UI_POD_1=$(kubectl get pod --selector app.kubernetes.io/name=ui -n ui -o json | jq -r '.items[0].metadata.name')
$ echo $UI_POD_1
ui-XXXX-XXX
$ kubectl exec -it ${UI_POD_1} -n ui -- curl -v telnet://catalog-mysql.catalog:3306 --connect-timeout 5
*   Trying XXX.XXX.XXX.XXX:3306...
* ipv4 connect timeout after 4999ms, move on!
* Failed to connect to catalog-mysql.catalog port 3306 after 5001 ms: Timeout was reached
* Closing connection 0
```
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

As you could see from the outputs, we can now connect to the 'catalog' service but not the database. Similarly, we can test to see if we are able to connect to other services like the 'order' service, which we should be able to. However, any calls to the internet or other third-party services should be blocked.

```bash wait=30 timeout=240
$ UI_POD_1=$(kubectl get pod --selector app.kubernetes.io/name=ui -n ui -o json | jq -r '.items[0].metadata.name')
$ echo $UI_POD_1
ui-XXXX-XXXX
$ kubectl exec -it ${UI_POD_1} -n ui -- curl -v orders.orders/orders --connect-timeout 5
*   Trying XXX.XXX.XXX.XXX:80...
* Connected to orders.orders (XXX.XXX.XXX.XXX) port 80 (#0)
> GET /orders HTTP/1.1
> Host: orders.orders
> User-Agent: curl/7.88.1
> Accept: */*
> 
< HTTP/1.1 200 
...
```
```bash wait=30 timeout=240
$ UI_POD_1=$(kubectl get pod --selector app.kubernetes.io/name=ui -n ui -o json | jq -r '.items[0].metadata.name')
$ echo $UI_POD_1
ui-XXXX-XXXX
$ kubectl exec -it ${UI_POD_1} -n ui -- curl -v www.google.com --connect-timeout 5
   Trying XXX.XXX.XXX.XXX:80...
*   Trying [XXXX:XXXX:XXXX:XXXX::XXXX]:80...
* Immediate connect fail for XXXX:XXXX:XXXX:XXXX::XXXX: Network is unreachable
...
```
Now that we have defined an effective egress policy for 'ui' component, let us focus on the catalog service and database components to implement a network policy to control traffic to the 'catalog' namespace.