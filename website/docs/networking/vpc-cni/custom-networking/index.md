---
title: "Custom Networking"
sidebar_position: 30
sidebar_custom_props: { "module": true }
description: "Flexible networking for pods with custom networking for Amazon Elastic Kubernetes Service."
---

::required-time{estimatedLabExecutionTimeMinutes="10"}

:::tip Before you start
Prepare your environment for this section:

```bash wait=30 timeout=300
$ prepare-environment networking/custom-networking
```

This will make the following changes to your lab environment:

- Attach a secondary CIDR range to the VPC
- Create three additional subnets from the secondary CIDR range

You can view the Terraform that applies these changes [here](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/networking/custom-networking/.workshop/terraform).

:::

By default, Amazon VPC CNI will assign Pods an IP address selected from the primary subnet. The primary subnet is the subnet CIDR that the primary ENI is attached to, usually the subnet of the node/host.

If the subnet CIDR is too small, the CNI may not be able to acquire enough secondary IP addresses to assign to your Pods. This is a common challenge for EKS IPv4 clusters.

Custom networking is one solution to this problem.

Custom networking addresses the IP exhaustion issue by assigning the Pod IPs from secondary VPC address spaces (CIDR). Custom networking support supports ENIConfig custom resource. The ENIConfig includes an alternate subnet CIDR range (carved from a secondary VPC CIDR), along with the security group(s) that the Pods will belong to. When custom networking is enabled, the VPC CNI creates secondary ENIs in the subnet defined under ENIConfig. The CNI assigns Pods an IP addresses from a CIDR range defined in a ENIConfig CRD.

![Insights](./assets/custom-networking-intro.webp)
