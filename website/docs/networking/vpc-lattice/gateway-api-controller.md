---
title: "AWS Gateway API Controller"
sidebar_position: 10
---

Gateway API is an open-source project managed by the Kubernetes networking community. It is a collection of resources that model application networking in Kubernetes. Gateway API supports resources such as GatewayClass, Gateway, and Route that have been implemented by many vendors and have broad industry support.

Originally conceived as a successor to the well-known Ingress API, the benefits of the Gateway API include (but are not limited to) explicit support for many commonly used networking protocols, as well as tightly integrated support for Transport Layer Security (TLS).

At AWS, we implement the Gateway API to integrate with Amazon VPC Lattice with the AWS Gateway API Controller. When
installed in your cluster, the controller watches for the creation of Gateway API resources such as gateways and routes and provisions corresponding Amazon VPC Lattice objects according to the mapping in the image below. The AWS Gateway API Controller is an open-source project and fully supported by Amazon.

![Kubernetes Gateway API Objects and VPC Lattice Components](/docs/networking/vpc-lattice/fundamentals-mapping.webp)

As shown in the figure, there are different personas associated with different levels of control in the Kubernetes Gateway API:

- Infrastructure provider: Creates the Kubernetes `GatewayClass` to identify VPC Lattice as the GatewayClass.
- Cluster operator: Creates the Kubernetes `Gateway`, which gets information from VPC Lattice related to the service networks.
- Application developer: Creates `HTTPRoute` objects that specify how the traffic is redirected from the gateway to backend Kubernetes services.

AWS Gateway API Controller integrates with Amazon VPC Lattice and allows you to:

- Handle network connectivity seamlessly between services across VPCs and accounts.
- Discover these services spanning multiple Kubernetes clusters
- Implement a defense-in-depth strategy to secure communication between those services.
- Observe the request/response traffic across the services.

In this chapter, we will create a new version of the `checkout` microservice and use Amazon VPC Lattice to seamlessly perform A/B testing.
