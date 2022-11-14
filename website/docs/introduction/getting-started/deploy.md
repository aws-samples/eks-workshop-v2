---
title: Deploying the application
sidebar_position: 10
---

The workshop modules use a sample microservices application to demonstrate the various concepts related to EKS. The sample application is composed of a set of Kubernetes manifests organized in a way that can be easily applied with Kustomize. This allows us to not only make the manifests easier to break apart and navigate, but also incrementally apply overlays and patches as we work through the various modules of this workshop.

If you want to understand more about Kustomize take a look at the [optional module](../kustomize.md) provided in this workshop.

There are different ways you can browse the manifests for the sample application depending on your comfort level. One way is to take a look at the GitHub repository for this workshop:

  [https://github.com/aws-samples/eks-workshop-v2/tree/main/environment/workspace/manifests](https://github.com/aws-samples/eks-workshop-v2/tree/main/environment/workspace/manifests)

Alternatively you can explore the manifests directly in your workshop environment. For example, use the `tree` command to visualize the directory structure:

```bash
$ tree --dirsfirst /workspace/manifests
|-- activemq
|   |-- configMap.yaml
|   |-- kustomization.yaml
|   |-- namespace.yaml
|   |-- service.yaml
|   |-- serviceAccount.yaml
|   `-- statefulSet.yaml
|-- assets
|   |-- configMap.yaml
|   |-- deployment.yaml
|   |-- kustomization.yaml
|   |-- namespace.yaml
|   |-- service.yaml
|   `-- serviceAccount.yaml
|-- carts
|   |-- configMap.yaml
|   |-- deployment-db.yaml
|   |-- deployment.yaml
|   |-- kustomization.yaml
|   |-- namespace.yaml
|   |-- service-db.yaml
|   |-- service.yaml
|   `-- serviceAccount.yaml
|-- catalog
|   |-- configMap.yaml
|   |-- deployment-mysql.yaml
|   |-- deployment.yaml
|   |-- kustomization.yaml
|   |-- namespace.yaml
|   |-- secrets.yaml
|   |-- service-mysql.yaml
|   |-- service.yaml
|   `-- serviceAccount.yaml
|-- checkout
|   |-- configMap.yaml
|   |-- deployment-redis.yaml
|   |-- deployment.yaml
|   |-- kustomization.yaml
|   |-- namespace.yaml
|   |-- service-redis.yaml
|   |-- service.yaml
|   `-- serviceAccount.yaml
|-- orders
|   |-- configMap.yaml
|   |-- deployment-mysql.yaml
|   |-- deployment.yaml
|   |-- kustomization.yaml
|   |-- namespace.yaml
|   |-- secrets.yaml
|   |-- service-mysql.yaml
|   |-- service.yaml
|   `-- serviceAccount.yaml
|-- other
|   |-- configMap.yaml
|   |-- kustomization.yaml
|   `-- namespace.yaml
|-- ui
|   |-- configMap.yaml
|   |-- deployment.yaml
|   |-- kustomization.yaml
|   |-- namespace.yaml
|   |-- service.yaml
|   `-- serviceAccount.yaml
`-- kustomization.yaml
```

To deploy the application, run the following `kubectl` command:

```bash timeout=300 wait=30
$ kubectl apply -k /workspace/manifests
```