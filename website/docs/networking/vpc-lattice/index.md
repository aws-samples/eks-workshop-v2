---
title: "Amazon VPC Lattice"
sidebar_position: 40
weight: 10
sidebar_custom_props: {"module": true}
---

:::tip Before you start
Prepare your environment for this section:

```bash timeout=300 wait=30
$ reset-environment 
```

:::

[Amazon VPC Lattice](https://aws.amazon.com/vpc/lattice/) is an application layer networking service that gives you a consistent way to connect, secure, and monitor service-to-service communication without any prior networking expertise. With VPC Lattice, you can configure network access, traffic management, and network monitoring to enable service-to-service communication consistently across VPCs and accounts, regardless of the underlying compute type.

The components of Amazon VPC Lattices include:



* **Service network**:
A logical grouping mechanism to simplify how users enable connectivity and apply common policies.

* **Service**:
Represents an Application Unit and can extend across all compute – instances, containers, serverless. It is build up of listeners, rules, and target-groups.

* **Service directory**:
A centralized registry of all services that have been associated with Amazon VPC Lattice.

* **Security policies**:
You can apply AWS Identity and Access Management (IAM) resource policies both at the Service Network and at the service level. They are called Auth Policies in Lattice.
