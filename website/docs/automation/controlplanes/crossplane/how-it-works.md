---
title: "How it works"
sidebar_position: 5
---

Running Crossplane in a cluster consists of two main parts:

1. The Crossplane controller which provides the core components
2. One or more Crossplane providers which each provide a controller and Custom Resource Definitions to integrate with a particular provider, such as AWS

The Crossplane controller and the AWS provider have been pre-installed in our EKS cluster, each running as a deployment in the `crossplane-system` namespace along with the `crossplane-rbac-manager`:

```bash
$ kubectl get deployment -n crossplane-system
```

These controllers will collaborate to watch for Kubernetes custom resources for AWS such as `rds.aws.crossplane.io.DBInstance` and will make API calls to the AWS API based on the configuration in those resources created. As resources are created the controller will feed back status updates to the custom resources in the `Status` fields.
