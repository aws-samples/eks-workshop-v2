---
title: "Secrets Management"
sidebar_position: 40
---

[Kubernetes Secret](https://kubernetes.io/docs/concepts/configuration/secret/) is a resource that helps cluster operators manage the deployment of sensitive information such as passwords, OAuth tokens, and ssh keys etc. These secrets can be mounted as data volumes or exposed as environment variables to the containers in a Pod, thus decoupling Pod deployment from managing sensitive data needed by the containerized applications within a Pod.

It has become a common practice for a DevOps Team to manage the YAML manifests for various Kubernetes resources and version control them using a Git repository. This enables them to integrate a Git repository with a GitOps workflow to do Continuous Delivery of such resources to an EKS cluster.
Kubernetes obfuscate sensitive data in a Secret by using a merely base64 encoding, also storing such files in a Git repository is extremely insecure as it is trivial to decode the base64 encoded data. This makes it difficult to manage the YAML manifests for Kubernetes Secrets outside a cluster.

There are a few different approaches you can use for secrets management, in this chapter for Secrets Management, we will cover a couple of them, [Sealed Secrets for Kubernetes](https://github.com/bitnami-labs/sealed-secrets) and [AWS Secrets Manager](https://docs.aws.amazon.com/secretsmanager/latest/userguide/intro.html).
