---
title: "kro - Kube Resource Orchestrator"
sidebar_position: 1
sidebar_custom_props: { "module": true }
description: "Compose and manage complex Kubernetes resource graphs with kro on Amazon Elastic Kubernetes Service."
---

::required-time

:::tip Before you start
Prepare your environment for this section:

```bash timeout=300 wait=30
$ prepare-environment automation/controlplanes/kro
```

This will make the following changes to your lab environment:

- Install the AWS Controller for DynamoDB in the Amazon EKS cluster

You can view the Terraform that applies these changes [here](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/automation/controlplanes/kro/.workshop/terraform).

:::

[kro (Kube Resource Orchestrator)](https://kro.run/) is an open-source Kubernetes operator that enables you to define custom APIs for creating groups of related Kubernetes resources. With kro, you create ResourceGraphDefinitions (RGDs) that use CEL (Common Expression Language) expressions to define relationships between resources and automatically determine their creation order.

kro allows you to compose multiple Kubernetes resources into higher-level abstractions with intelligent dependency handling - it automatically determines the correct order to deploy resources by analyzing how they reference each other. You can pass values between resources using CEL expressions, include conditional logic, and define default values to simplify the user experience. 

kro works with any Kubernetes resources and CRDs, making it particularly powerful when you need to provision AWS services using ACK controllers while simultaneously creating the necessary Kubernetes resources like secrets, configmaps, and service accounts - all from a single ResourceGraphDefinition that provides a complete, ready-to-use solution.

kro differs from ACK and Crossplane in its approach to resource management:

- **ACK** provides direct one-to-one mappings between AWS services and Kubernetes resources
- **Crossplane** offers comprehensive multi-cloud infrastructure orchestration with composition capabilities  
- **kro** focuses on creating reusable templates that combine multiple resources into cohesive patterns

In this lab, we'll explore kro's capabilities by first deploying the complete **Carts** application with an in-memory database using a WebApplication ResourceGraphDefinition. We'll then enhance this by composing a WebApplicationDynamoDB ResourceGraphDefinition that builds on the base WebApplication template to add Amazon DynamoDB storage.