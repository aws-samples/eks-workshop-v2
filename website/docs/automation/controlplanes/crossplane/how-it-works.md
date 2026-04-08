---
title: "How it works"
sidebar_position: 5
---

Crossplane operates within a cluster using two primary components:

1. The Crossplane controller, which provides the core functionality
2. One or more Crossplane providers, each offering a controller and Custom Resource Definitions to integrate with a specific provider, such as AWS

In our EKS cluster, we've pre-installed the Crossplane controller, the Upbound AWS provider, and the necessary components. These run as deployments in the `crossplane-system` namespace, alongside the `crossplane-rbac-manager`:

```bash
$ kubectl get deployment -n crossplane-system
NAME                                         READY   UP-TO-DATE   AVAILABLE   AGE
crossplane                                   1/1     1            1           3h7m
crossplane-rbac-manager                      1/1     1            1           3h7m
upbound-aws-provider-dynamodb-23a48a51e223   1/1     1            1           3h6m
upbound-provider-family-aws-1ac09674120f     1/1     1            1           21h
```

Here, `upbound-provider-family-aws` represents the Crossplane provider for Amazon Web Services (AWS), developed and supported by Upbound. The `upbound-aws-provider-dynamodb` is a subset dedicated to deploying DynamoDB via Crossplane.

Crossplane simplifies the process for developers to request infrastructure resources using Kubernetes manifests called claims. As illustrated in the diagram below, claims are the only namespace-scoped Crossplane resources, serving as the developer interface and abstracting implementation details. When a claim is deployed to the cluster, it creates a Composite Resource (XR), a Kubernetes custom resource representing one or more cloud resources defined through templates called Compositions. The Composite Resource then creates one or more Managed Resources, which interact with the AWS API to request the creation of the desired infrastructure resources.

![Crossplane claim](/docs/automation/controlplanes/crossplane/claim-architecture-drawing.webp)

This architecture allows for a clear separation of concerns between developers, who work with high-level abstractions (claims), and platform teams, who define the underlying infrastructure implementations (Compositions and Managed Resources).
