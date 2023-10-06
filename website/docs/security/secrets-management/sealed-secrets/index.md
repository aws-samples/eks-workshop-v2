---
title: "Securing Secrets Using Sealed Secrets"
sidebar_position: 51
---

[Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets) provides a mechanism to encrypt a Secret object so that it is safe to store - even to a public repository. A SealedSecret can be decrypted only by the controller running in the Kubernetes cluster and nobody else is able to obtain the original Secret from a SealedSecret.

In this chapter, you will use SealedSecrets to encrypt YAML manifests pertaining to Kubernetes Secrets as well as be able to deploy these encrypted Secrets to your EKS clusters using normal workflows with tools such as [kubectl](https://kubernetes.io/docs/reference/kubectl/).
