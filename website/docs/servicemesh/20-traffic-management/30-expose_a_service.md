---
title: Exposing a service with ISTIO Ingress Gateway
sidebar_position: 30
weight: 5
---
It's common to us a Kubernetes Ingress to access an internal kubernetes service from the outside. In this module, you configure the traffic to enter through an Istio ingress gateway, in order to apply Istio control on traffic to your microservices.


By default, kubernetes services running in namespaces managed by Istio service mesh are not exposed outside the cluster. For the Kubernetes service you want to expose externally, you must deploy an Istio Ingress Gateway as a LoadBalancer for it, and then define an Istio VirtualService with the necessary routes. Let's see how that works.

### Enable Istio in a Namespace
You must manually enable Istio in each namespace that you want to track or control with Istio. When Istio is enabled in a namespace, the Envoy sidecar proxy is injected into all new workloads deployed in that namespace. 

This namespace setting will only affect new workloads in the namespace. Any preexisting workloads will need to be re-deployed to leverage the sidecar auto injection.

let's create a new namespace to play with.
```shell
kubectl create ns test
```

Now let's label this namespace to automatically inject Envoy sidecar proxy into all pods going to run in this namespace.
```shell
kubectl label namespace test istio-injection=enabled
```

#### Verifying it:
Let's verify that automatic Istio sidecar injection is enabled, by deploying the book-info sampe app into this namespace

```shell
kubectl apply -n test -f https://raw.githubusercontent.com/istio/istio/master/samples/bookinfo/platform/kube/bookinfo.yaml 
```
Output:
```shell
service/details created
serviceaccount/bookinfo-details created
deployment.apps/details-v1 created
service/ratings created
serviceaccount/bookinfo-ratings created
deployment.apps/ratings-v1 created
service/reviews created
serviceaccount/bookinfo-reviews created
deployment.apps/reviews-v1 created
deployment.apps/reviews-v2 created
deployment.apps/reviews-v3 created
service/productpage created
serviceaccount/bookinfo-productpage created
deployment.apps/productpage-v1 created
```

Now, if you get pods running, you will see 2 containers running per pod. That's because the Envoy proxy container has been injected automatically to all of them. This envoy proxy has not been defined in the [manifest](https://raw.githubusercontent.com/istio/istio/master/samples/bookinfo/platform/kube/bookinfo.yaml) used to deply this book-info sample app.  

```shell
kubectl get po -n test
```
Output:
```shell
NAME                             READY   STATUS    RESTARTS   AGE
details-v1-698b5d8c98-9f2sz      2/2     Running   0          27s
productpage-v1-bf4b489d8-7d44d   2/2     Running   0          26s
ratings-v1-5967f59c58-g7877      2/2     Running   0          27s
reviews-v1-9c6bb6658-s97gt       2/2     Running   0          27s
reviews-v2-8454bb78d8-f9r25      2/2     Running   0          27s
reviews-v3-6dc9897554-5fnqp      2/2     Running   0          27s
```
**_Note:_**

If you need to **exclude** a workload from getting injected with the Istio sidecar, use the following annotation on the workload:
```yaml
sidecar.istio.io/inject: “false”
```

### Expose a service
If you listed services into this namespace, you will notice that the service type of all of them is ClusterIP, which means that they can only be seen into the cluster. 

```shell
kubectl get svc -n test
```
Output:
```shell
NAME          TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE
details       ClusterIP   172.20.188.169   <none>        9080/TCP   51m
productpage   ClusterIP   172.20.146.158   <none>        9080/TCP   51m
ratings       ClusterIP   172.20.89.160    <none>        9080/TCP   51m
reviews       ClusterIP   172.20.0.229     <none>        9080/TCP   51m
```

How we can expose a service outside the cluster? Let's see how we can do that with the productpage for example.

To do so we define two Istio resources, `Gateway` and `VirtualService`.
Gateway configurations are applied to standalone Envoy proxies that are running at the edge of the mesh. 
```yaml
kubectl apply -n test -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: bookinfo-gateway
spec:
  selector:  
    istio: ingressgateway 
  servers: 
  - port:
      number: 80 
      name: http
      protocol: HTTP   
    hosts: # The addresses that can be used by a client when attempting to connect to a service.
    - "*"
EOF
```
Here we point to the default istio `ingressgateway` proxy service running in `istio-system` namespace to expose the service throug the AWS ELB created for this ingress gateway.

This gateway is a loadbalancer that listens or accept incoming traffic on port 80 that uses HTTP protocol (could be HTTP,HTTPS,GRPC,HTTP2,MONGO or TCP)

This gateway configuration here, allows clients to connect on port 80 and to use any address (*) when attemting to connect to a service

The gateway here, does not specify any traffic routing rules for the kuberenets service ***productpage***. To make the gateway work as intended, you must also create a virtual service that defines traffic routing rules for the intended kuberenets service "productpage" and bind it to the gateway.


```yaml
kubectl apply -n test -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: bookinfo
spec:
  hosts:
  - "*"

  gateways:
  - bookinfo-gateway 
  
  http:
  - match:
    - uri:
        exact: /productpage    
    - uri:
        prefix: /static
    - uri:
        exact: /login
    - uri:
        exact: /logout
    - uri:
        prefix: /api/v1/products
    route:
    - destination:
        # Provide the destination service name using either a relative or an absolute path.
        host: productpage # productpage.test.svc.cluster.local 
        port:
          number: 9080
EOF
```

In VirtualService, you can define the routing rules for the external traffic.

In this example, traffic will be directed to the `destination` service, if it meets any of the listed rules. For instance, they will be directed to the destination service *productpage* if the uri provided was */productpage*, */static*, */login*, etc.

The `hosts` field contains a list of the destinations/addresses that the client uses when sending requests to the service where routing rules listed below apply.

As in this example, you can make a single set of routing rules that apply to all matching services by using wildcard ("*") prefixes under `hosts`.

To make the gateway to work as intended with those routing rules, you must bind/link this virtual service resource to the gateway resource name **bookinfo-gateway** you created in the previous step. 

**_Note:_**

Under `hosts` attribue in *Gateway* and *virtualService* resources, you can remove "*", and only allow the dns name of the **istio-ingressgateway** servcie running in istio-ststem namespace, which is the AWS LB dns name that Istio created during the installation of Istio. Or to only allow dns cname/alias records (in Route53 for example) pointing to the dns name of the **istio-ingressgateway** servcie. Check this [page](https://istio.io/v1.14/docs/tasks/traffic-management/ingress/ingress-control/#determining-the-ingress-ip-and-ports) for more info.

#### Verify it:
Let's verify that the service has been exposed as intended with the routing rules that have been set.

Because the gateway we created is binded to the **istio-ingressgateway** service running in **istio-system** namespace, you can reach the endpoint of this gateway using the same domain name of the AWS ELB that Istio created for this istio-ingressgateway service. Let's see how that works?


Execute the following command to the dns hostname of the AWS load balancer of the **istio-ingressgateway** service, and then assign it to an environment variable.
```shell
export ISTIO_IG_HOSTNAME=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo $ISTIO_IG_HOSTNAME
```
Output:
```buttonless
ac8bed13fd78247e995b42664063ce47-1403049919.us-east-1.elb.amazonaws.com
```
Remember, the gateway you created earlier is exposed throug this istio-ingressgateway service which is in turn exposed throug an AWS Loadbalancer. and the destination service of the virtualService you created was *productpage* 

So to access it we hit the same dns name of the istio-ingressgateway loadbalancer, by using the path */productpage*

```shell
curl $ISTIO_IG_HOSTNAME/productpage
```
Output:
```html
<!DOCTYPE html>
<html>
  <head>
    <title>Simple Bookstore App</title>
...
      <dl>
        <dt>Reviews served by:</dt>
        <u>reviews-v2-8454bb78d8-f9r25</u>
...
```
You can also test accessing the page using the browser:
![productpage](../assets/productpage.png)

**Congratulations!** By reaching this point, you have successfully exposed the kubernetes service productpage externally through the Istio ingress gateway.