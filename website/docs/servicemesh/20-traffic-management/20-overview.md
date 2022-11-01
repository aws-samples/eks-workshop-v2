---
title: Overview
sidebar_position: 20
weight: 5
---

## Advantages of using ISTIO for traffic management:
* Understanding how various services on the network interact with each other.
* Ability to Inspect traffic between services.
* Percentage-based routing with granular policies.
* Thousands of services' policies can be automated.
* Decouple the network from your application code.

## ISTIO Traffic Management API Resources:
You might want to direct a particular percentage of traffic to a new version of a service as part of A/B testing, or apply a different load balancing policy to traffic for a particular subset of service instances. You might also want to apply special rules to traffic coming into or out of your mesh, or add an external dependency of your mesh to the service registry. You can do all this and more by adding your own traffic configuration to Istio using Istio’s traffic management API.

API is specified using Kubernetes custom resource definitions (CRDs), which you can configure using YAML, as you’ll see in the coming sections of this chapter.

These custom resources are:
* Gateways
* Virtual services
* Destination rules
* Service entries


### Gateway
The Gateway functions as a sort of a loadbalancer that operates at the edge of the mesh receiving incoming or outgoing HTTP/TCP connections. It's similar to AWS ELB Listener where you define incoming ports, protocol, and TLS termination, etc.<br/><br/>
So the main purpose of the gateway resource is to expose a kubernetes service externally if needed.



```yaml
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
    hosts:
    - "*"
  - port:
      number: 443
      name: https
      protocol: HTTPS
    hosts:
    - ext-host.example.com
    tls:
      mode: SIMPLE
      credentialName: ext-host-cert    
```
So in this resource you are setting:
* The ports that should be exposed
* The type of protocols to use
* Enabling TLS termination if needed.


### VirtualService
The Virtual Service functions as a replacement for Kubernetes ingress resource. It lets you configure how requests are routed to a Kubernetes service. 

Each virtual service consists of a set of routing rules that are evaluated in order, letting Istio match each given request to the virtual service to a specific real destination within the mesh. 

In the following example, virtual service splitting the coming traffic by routing requests to different versions of a service.

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: reviews
spec:
  hosts:
    - reviews
  gateways:
    - bookinfo-gateway
  http:
  - route:
    - destination:
        host: reviews
        subset: v1
      weight: 60
    - destination:
        host: reviews
        subset: v2
      weight: 30
    - destination:
        host: reviews
        subset: v3
      weight: 10     
```


### DestinationRule
The virtual services are concerned with how traffic is routed to a certain destination, and destination rules are used to configure what happens to traffic for that destination.

Destination rules are applied to the "actual" destination of the traffic after virtual service routing rules have been evaluated.

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: reviews
spec:
  host: reviews
  subsets:
  - name: v1
    labels:
      version: v1
  - name: v2
    labels:
      version: v2
    trafficPolicy:
      loadBalancer:
        simple: ROUND_ROBIN
  - name: v3
    labels:
      version: v3
```
Destination rules are specifically used to specify named service subsets, such as grouping instances of a service by version.

You can then use these service subsets in the routing rules of virtual services to control the traffic to different instances of your services as we saw in the above virtualService example.


### ServiceEntry
You use a service entry to add an entry to the service registry that Istio maintains internally. After you add the service entry, the Envoy proxies can send traffic to the service as if it was a service in your mesh. Configuring service entries allows you to manage traffic for services running outside of the mesh.

The following example mesh-external service entry adds the ext-svc.example.com external dependency to Istio’s service registry:

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: ServiceEntry
metadata:
  name: svc-entry
spec:
  hosts:
  - ext-svc.example.com
  ports:
  - number: 443
    name: https
    protocol: HTTPS
  location: MESH_EXTERNAL
  resolution: DNS
```

Now, let's get some hands-on and see how those Traffic Management resources work together in Istio
