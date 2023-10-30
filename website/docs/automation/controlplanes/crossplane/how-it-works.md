---
title: "How it works"
sidebar_position: 5
---

Running Crossplane in a cluster consists of two main parts:

1. The Crossplane controller which provides the core components
2. One or more Crossplane providers which each provide a controller and Custom Resource Definitions to integrate with a particular provider, such as AWS

The Crossplane controller and the Upbond provider have been pre-installed in our EKS cluster, each running as a deployment in the `crossplane-system` namespace along with the `crossplane-rbac-manager`:

```bash
$ kubectl get deployment -n crossplane-system
```

Crossplane provides a simplified interface for developers to request infrastructure resources via Kubernetes manifests called claims. As shown in this diagram, claims are the only namespace-scoped Crossplane resources, serving as the developer interface and abstracting away implementation details. When a claim is deployed to the cluster, it creates a Composite Resource (XR), a Kubernetes custom resource representing one or more cloud resources defined through templates called Compositions. The Composite Resource creates one or more Managed Resources which interact with the AWS API to request the creation of the desired infrastructure resources. 

![Crossplane claim](./assets/claim-architecture-drawing.png)
