---
title: "Policy management with Kyverno"
sidebar_position: 70
sidebar_custom_props: { "module": true }
description: "Apply policy-as-code with Kyverno on Amazon Elastic Kubernetes Service."
---

::required-time

:::tip Before you start
Prepare your environment for this section:

```bash timeout=600 wait=30
$ prepare-environment security/kyverno
```

This will make the following changes to your lab environment:

Install the following Kubernetes addons in the EKS cluster:

- Kyverno Policy Manager
- Kyverno Policies
- Policy Reporter

You can view the Terraform that applies these changes [here](https://github.com/aws-samples/eks-workshop-v2/tree/main/manifests/modules/security/kyverno/.workshop/terraform).
:::

As containers are increasingly adopted in production environments, DevOps, Security, and Platform teams require an effective solution to collaborate and manage Governance and [Policy-as-Code (PaC)](https://aws.github.io/aws-eks-best-practices/security/docs/pods/#policy-as-code-pac). This ensures that all teams share the same source of truth regarding security and use a consistent baseline "language" when describing their individual needs.

Kubernetes, by its nature, is designed as a tool to build upon and orchestrate, which means it lacks pre-defined guardrails out of the box. To provide builders with a way to control security, Kubernetes offers [Pod Security Admission (PSA)](https://kubernetes.io/docs/concepts/security/pod-security-admission/) starting from version 1.23. PSA is a built-in admission controller that implements the security controls outlined in the [Pod Security Standards (PSS)](https://kubernetes.io/docs/concepts/security/pod-security-standards/), and is enabled by default in Amazon Elastic Kubernetes Service (EKS).

### What is Kyverno?

[Kyverno](https://kyverno.io/) (Greek for "govern") is a policy engine specifically designed for Kubernetes. It is a Cloud Native Computing Foundation (CNCF) project that enables teams to collaborate and enforce Policy-as-Code.

The Kyverno policy engine integrates with the Kubernetes API server as a [Dynamic Admission Controller](https://kubernetes.io/docs/reference/access-authn-authz/extensible-admission-controllers/), allowing policies to **mutate** and **validate** inbound Kubernetes API requests. This ensures compliance with defined rules prior to the data being persisted and applied to the cluster.

Kyverno uses declarative Kubernetes resources written in YAML, eliminating the need to learn a new policy language. Results are available as Kubernetes resources and events.

Kyverno policies can be used to **validate**, **mutate**, and **generate** resource configurations, as well as **validate** image signatures and attestations, providing all the necessary building blocks for comprehensive software supply chain security standards enforcement.

### How Kyverno Works

Kyverno operates as a Dynamic Admission Controller in a Kubernetes Cluster. It receives validating and mutating admission webhook HTTP callbacks from the Kubernetes API server and applies matching policies to return results that enforce admission policies or reject requests. It can also be used to audit requests and monitor the security posture of the environment before enforcement.

The diagram below illustrates the high-level logical architecture of Kyverno:

![KyvernoArchitecture](/docs/security/kyverno/ky-arch.webp)

The two major components are the Webhook Server and the Webhook Controller. The **Webhook Server** handles incoming AdmissionReview requests from the Kubernetes API server and sends them to the Engine for processing. It is dynamically configured by the **Webhook Controller**, which monitors installed policies and modifies the webhooks to request only the resources matched by those policies.

---

Before proceeding with the labs, validate the Kyverno resources provisioned by the `prepare-environment` script:

```bash
$ kubectl -n kyverno get all
NAME                                                 READY   STATUS    RESTARTS   AGE
pod/kyverno-admission-controller-8648694c5-hv8vb     1/1     Running   0          97s
pod/kyverno-background-controller-6fbcb79d89-kt7w9   1/1     Running   0          97s
pod/kyverno-cleanup-controller-549855c6d8-2jjtn      1/1     Running   0          96s
pod/kyverno-reports-controller-668c67d758-4s57g      1/1     Running   0          96s

NAME                                            TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE
service/kyverno-background-controller-metrics   ClusterIP   172.16.74.233    <none>        8000/TCP   98s
service/kyverno-cleanup-controller              ClusterIP   172.16.29.137    <none>        443/TCP    98s
service/kyverno-cleanup-controller-metrics      ClusterIP   172.16.119.134   <none>        8000/TCP   98s
service/kyverno-reports-controller-metrics      ClusterIP   172.16.42.244    <none>        8000/TCP   98s
service/kyverno-svc                             ClusterIP   172.16.151.20    <none>        443/TCP    99s
service/kyverno-svc-metrics                     ClusterIP   172.16.60.130    <none>        8000/TCP   98s

NAME                                            READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/kyverno-admission-controller    1/1     1            1           98s
deployment.apps/kyverno-background-controller   1/1     1            1           98s
deployment.apps/kyverno-cleanup-controller      1/1     1            1           97s
deployment.apps/kyverno-reports-controller      1/1     1            1           97s

NAME                                                       DESIRED   CURRENT   READY   AGE
replicaset.apps/kyverno-admission-controller-8648694c5     1         1         1       98s
replicaset.apps/kyverno-background-controller-6fbcb79d89   1         1         1       98s
replicaset.apps/kyverno-cleanup-controller-549855c6d8      1         1         1       97s
replicaset.apps/kyverno-reports-controller-668c67d758      1         1         1       97s
```
