---
title: "Securing Secrets Using Sealed Secrets"
sidebar_position: 50
---

:::tip Before you start
Prepare your environment for this section:

```bash timeout=300 wait=30
$ reset-environment 
```

:::

[Kubernetes Secret](https://kubernetes.io/docs/concepts/configuration/secret/) is a resource that helps cluster operators manage the deployment of sensitive information such as passwords, OAuth tokens, and ssh keys etc. These secrets can be mounted as data volumes or exposed as environment variables to the containers in a pod, thus decoupling pod deployment from managing sensitive data needed by the containerized applications within a pod.

It has become a common practice for a DevOps Team to manage the YAML manifests for various Kubernetes resources and version control them using a Git repository. This enables them to integrate a Git repository with a GitOps workflow to do Continuous Delivery of such resources to an EKS cluster. The sensitive data in a Secret is obfuscated by using merely base64 encoding and storing such files in a Git repository is extremely insecure as it is trivial to decode the base64 encoded data. This makes it difficult to manage the YAML manifests for Kubernetes Secrets outside the cluster.

[Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets) provides a mechanism to encrypt a Secret object so that it is safe to store - even to a public repository. A SealedSecret can be decrypted only by the controller running in the Kubernetes cluster and nobody else is able to obtain the original Secret from a SealedSecret. 

In this chapter, you will use SealedSecrets to encrypt YAML manifests pertaining to Kubernetes Secrets as well as be able to deploy these encrypted Secrets to your EKS clusters using normal workflows with tools such as [kubectl](https://kubernetes.io/docs/reference/kubectl/).