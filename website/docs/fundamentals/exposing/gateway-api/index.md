---
title: "Gateway API"
sidebar_position: 50
sidebar_custom_props: { "module": true }
description: "Expose and route traffic to Kubernetes services using the Gateway API on Amazon Elastic Kubernetes Service."
---

::required-time

:::tip Before you start
Prepare your environment for this section:

```bash timeout=300 wait=30
$ prepare-environment exposing/gateway-api
```

This will make the following changes to your lab environment:

- Install Gateway API CRDs (Custom Resource Definitions)
- Install AWS Load Balancer Controller Gateway API CRDs
- Create an IAM role for the AWS Load Balancer Controller

You can view the Terraform that applies these changes [here](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/exposing/gateway-api/.workshop/terraform).

:::

The [Gateway API](https://gateway-api.sigs.k8s.io/) is the successor to the Kubernetes Ingress API, providing a more expressive and extensible model for managing traffic routing into your cluster. Unlike Ingress, which combines infrastructure and routing concerns into a single resource, Gateway API uses a role-oriented design that separates responsibilities:

- **GatewayClass** — Defines the controller (managed by infrastructure providers)
- **Gateway** — Provisions load balancer infrastructure (managed by cluster operators)
- **HTTPRoute** — Defines routing rules to backend services (managed by application developers)

This separation allows different teams to manage their own resources independently, improving security and operational clarity.

In this module, we'll explore how to use Gateway API with the AWS Load Balancer Controller to expose and route traffic to our sample application. We'll cover three key scenarios:

1. **Exposing the UI** — Create a GatewayClass, Gateway, and HTTPRoute to provision an ALB and route traffic to the UI service
2. **Path-Based Routing** — Add a second HTTPRoute for the Catalog API, demonstrating how multiple services share a single Gateway (and ALB) with cross-namespace routing
3. **Canary Deployment** — Use weighted traffic splitting to gradually shift traffic from one version of the UI to another
