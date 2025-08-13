---
title: "Network Policies"
sidebar_position: 10
sidebar_custom_props: { "module": true }
description: "Restrict network traffic to and from pods in Amazon Elastic Kubernetes Service with network policies."
---

::required-time

:::tip Before you start
Prepare your environment for this section:

```bash wait=30 timeout=600
$ prepare-environment networking/network-policies
```

:::

By default, Kubernetes allows all pods to freely communicate with each other with no restrictions. Kubernetes Network Policies enable you to define and enforce rules on the flow of traffic between pods, namespaces, and IP blocks (CIDR ranges). They act as a virtual firewall, allowing you to segment and secure your cluster by specifying ingress (incoming) and egress (outgoing) network traffic rules based on various criteria such as pod labels, namespaces, IP addresses, and ports.

Below is an example network policy with an explanation of some key elements:

::yaml{file="manifests/modules/networking/network-policies/apply-network-policies/example-network-policy.yaml" paths="metadata,spec.podSelector,spec.policyTypes,spec.ingress,spec.egress" title="example-network-policy.yaml"}

1. Similar to other Kubernetes objects, `metadata` allows you to specify the name and namespace for the given network policy
2. `spec.podSelector` allows for the selection of specific pods based on their labels within the namespace to which the given network policy will be applied. If an empty pod selector or matchLabels is specified in the specification, then the policy will be applied to all the pods within the namespace.
3. `spec.policyTypes` specifies whether the policy will be applied to ingress traffic, egress traffic, or both for the selected pods. If you do not specify this field, then the default behavior is to apply the network policy to ingress traffic only, unless the network policy has an egress section, in which case the network policy will be applied to both ingress and egress traffic.
4. `ingress` allows for ingress rules to be configured that specify from which pods (`podSelector`), namespace (`namespaceSelector`), or CIDR range (`ipBlock`) traffic is allowed to the selected pods and which port or port range can be used. If a port or port range is not specified, any port can be used for communication.
5. `egress` allows for egress rules to be configured that specify to which pods (`podSelector`), namespace (`namespaceSelector`), or CIDR range (`ipBlock`) traffic is allowed from the selected pods and which port or port range can be used. If a port or port range is not specified, any port can be used for communication.

For more information about what capabilities are allowed or restricted for Kubernetes network policies, refer to the [Kubernetes docs](https://kubernetes.io/docs/concepts/services-networking/network-policies/).

In addition to network policies, Amazon VPC CNI in IPv4 mode offers a powerful feature known as "Security Groups for Pods." This feature enables you to use Amazon EC2 security groups to define comprehensive rules governing inbound and outbound network traffic to and from the pods deployed on your nodes. While there is overlap in capabilities between security groups for pods and network policies, there are some key differences.

- Security groups allow control of ingress and egress traffic to CIDR ranges, whereas network policies allow control of ingress and egress traffic to pods, namespaces as well as CIDR ranges.
- Security groups allow control of ingress and egress traffic from other security groups, which is not available for network policies.

Amazon EKS strongly recommends employing network policies in conjunction with security groups to restrict network communication between pods, thus reducing the attack surface and minimizing potential vulnerabilities.
