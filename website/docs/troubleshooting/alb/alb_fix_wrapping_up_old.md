---
title: "Wrapping it up OLD"
sidebar_position: 33
---

## Wrapping it up

Here’s the general flow of how Load Balancer Controller works:

1. The controller watches for [ingress events](https://kubernetes.io/docs/concepts/services-networking/ingress/#ingress-controllers) from the API server. When it finds ingress resources that satisfy its requirements, it begins the creation of AWS resources.

2. An [ALB](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/introduction.html) (ELBv2) is created in AWS for the new ingress resource. This ALB can be internet-facing or internal. You can also specify the subnets it's created in using annotations.

3. [Target Groups](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-target-groups.html) are created in AWS for each unique Kubernetes service described in the ingress resource.

4. [Listeners](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-listeners.html) are created for every port detailed in your ingress resource annotations. When no port is specified, sensible defaults (80 or 443) are used. Certificates may also be attached via annotations.

5. [Rules](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/listener-update-rules.html) are created for each path specified in your ingress resource. This ensures traffic to a specific path is routed to the correct Kubernetes Service.

---
