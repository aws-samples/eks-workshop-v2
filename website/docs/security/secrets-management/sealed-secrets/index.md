---
title: "Securing Secrets Using Sealed Secrets (optional)"
sidebar_position: 70
sidebar_custom_props: {"module": true}
---

:::alert
The [Sealed Secrets](https://docs.bitnami.com/tutorials/sealed-secrets) project is not related to AWS Services but a third party open-source tool from [Btinami Labs](https://bitnami.com/)
:::


:::tip Before you start
Prepare your environment for this section:

```bash timeout=300 wait=30
$ prepare-environment security/sealed-secrets
```
:::

[Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets) provides a mechanism to encrypt a Secret object so that it is safe to store - even to a public repository. A SealedSecret can be decrypted only by the controller running in the Kubernetes cluster and nobody else is able to obtain the original Secret from a SealedSecret.

In this chapter, you will use SealedSecrets to encrypt YAML manifests pertaining to Kubernetes Secrets as well as be able to deploy these encrypted Secrets to your EKS clusters using normal workflows with tools such as [kubectl](https://kubernetes.io/docs/reference/kubectl/).
