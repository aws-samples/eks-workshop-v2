---
title: "Argo CD App of Apps"
sidebar_position: 4
sidebar_custom_props: { "module": true }
---

:::tip Before you start
Prepare your environment for this section:

```bash timeout=300 wait=30
$ reset-environment
```

:::

[Argo CD](https://argoproj.github.io/cd/) is a declarative, GitOps continuous delivery tool for Kubernetes. The [Amazon EKS Blueprints for Terraform](https://aws-ia.github.io/terraform-aws-eks-blueprints/) provisions Argo CD as an add-on into an EKS cluster, and can optionally bootstrap your workloads from public and private Git repositories.

The [Argo CD add-on](https://aws-ia.github.io/terraform-aws-eks-blueprints/add-ons/argocd/) allows platform teams to combine cluster provisioning and workload bootstrapping in a single step and enables use cases such as replicating an existing running production cluster in a different region. This is important for business continuity and disaster recovery cases as well as for cross-regional availability and geographical expansion.

Another use case can be a deployment of a set of applications to different environments (DEV, TEST, PROD ...) using common set of Kubernetes manifest and customizations specific to an environment.

We can use [Argo CD App of Apps pattern](https://argo-cd.readthedocs.io/en/stable/operator-manual/cluster-bootstrapping/) to implement this use case. This pattern allows us to specify one Argo CD Application that consists of other applications.

![argo-cd-app-of-apps](assets/argocd-app-of-apps.png)

We use [EKS Workshop Git repository](https://github.com/aws-samples/eks-workshop-v2/tree/main/environment/workspace/manifests) as a Git repository with Common Manifest. This repository will be used as a basis for each environment.

```
.
|-- manifests
| |-- assets
| |-- carts
| |-- catalog
| |-- checkout
| |-- orders
| |-- other
| |-- rabbitmq
| `-- ui
```
