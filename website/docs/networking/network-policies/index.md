---
title: "Network Policies"
sidebar_position: 50
sidebar_custom_props: {"module": true}
---

:::tip Before you start
Prepare your environment for this section:

```bash wait=30 timeout=300
$ prepare-environment networking/network-policies
```

This will make the following changes to your lab environment:
- Will mount the BPF directory on all of the managed nodegroup nodes within the cluster if the cluster version is 1.25 or 1.26.

You can view the Terraform that applies these changes [here](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/networking/network-policies/.workshop/terraform).

:::

By default, Kubernetes allows all pods to freely communicate with each other with no restrictions. Kubernetes Network Policies enable you to define and enforce rules on the flow of traffic between pods, namespaces, and IP blocks (CIDR ranges). They act as a virtual firewall, allowing you to segment and secure your cluster by specifying ingress (incoming) and egress (outgoing) network traffic rules based on various criteria such as pod labels, namespaces, IP addresses, and ports. 

Below is an example of a network policy,

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: test-network-policy
  namespace: default
spec:
  podSelector:
    matchLabels:
      role: db
  policyTypes:
    - Ingress
    - Egress
  ingress:
    - from:
        - ipBlock:
            cidr: 172.17.0.0/16
            except:
              - 172.17.1.0/24
        - namespaceSelector:
            matchLabels:
              project: myproject
        - podSelector:
            matchLabels:
              role: frontend
      ports:
        - protocol: TCP
          port: 6379
  egress:
    - to:
        - ipBlock:
            cidr: 10.0.0.0/24
      ports:
        - protocol: TCP
          port: 5978
```

The network policy specification contains the following key segments:
* **metadata**: similar to other Kubernetes objects, it allows you to specify the name and namespace for the given network policy.
* **spec.podSelector**: allows for the selection of specific pods based on their labels within the namespace to which the given network policy will be applied. If an empty pod selector or matchLabels is specified in the specification, then the policy will be applied to all the pods within the namespace.
* **spec.policyTypes**: specifies whether the policy will be applied to ingress traffic, egress traffic, or both for the selected pods. If you do not specify this field, then the default behaviour is to apply the network policy to ingress traffic only, unless the network policy has an egress section, in which case the network policy will be applied to both ingress and egress traffic.
* **ingress**: allows for ingress rules to be configured that specify from which pods (podSelector), namespace (namespaceSelector), or CIDR range (ipBlock) traffic is allowed to the selected pods and  which port or port range can be used. If a port or port range is not specified, any port can be used for communication.

For more information about what capabilities are allowed or restricted for Kurbernetes network policies, refer to the [Kubernetes docs](https://kubernetes.io/docs/concepts/services-networking/network-policies/).

In addition to network policies, Amazon VPC CNI in IPv4 mode offers a powerful feature known as "Security Groups for Pods." This feature enables you to use Amazon EC2 security groups to define comprehensive rules governing inbound and outbound network traffic to and from the pods deployed on your nodes. While there is overlap in capabilities between security groups for pods and network policies, there are some key differences.
* Security groups allow control of ingress and egress traffic to CIDR ranges, whereas network policies allow control of ingress and egress traffic to pods, namespaces as well as CIDR ranges.
* Security groups allow control of ingress and egress traffic from other security groups, which is not available for network policies.

Amazon EKS strongly recommends employing network policies in conjunction with security groups to restrict network communication between pods, thus reducing the attack surface and minimising potential vulnerabilities.