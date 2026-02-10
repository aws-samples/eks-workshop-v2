---
title: "Policy management with Kyverno"
sidebar_position: 70
sidebar_custom_props: { "module": true }
description: "Apply policy-as-code with Kyverno on Amazon Elastic Kubernetes Service."
---

::required-time

:::tip Before you start
Prepare your environment for this section:

```bash timeout=300 wait=30
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
NAME                                                           READY   STATUS      RESTARTS   AGE
pod/kyverno-admission-controller-594c99487b-wpnsr              1/1     Running     0          8m15s
pod/kyverno-background-controller-7547578799-ltg7f             1/1     Running     0          8m15s
pod/kyverno-cleanup-admission-reports-28314690-6vjn4           0/1     Completed   0          3m20s
pod/kyverno-cleanup-cluster-admission-reports-28314690-2jjht   0/1     Completed   0          3m20s
pod/kyverno-cleanup-controller-79575cdb59-mlbz2                1/1     Running     0          8m15s
pod/kyverno-reports-controller-8668db7759-zxjdh                1/1     Running     0          8m15s
pod/policy-reporter-57f7dfc766-n48qk                           1/1     Running     0          7m53s

NAME                                            TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE
service/kyverno-background-controller-metrics   ClusterIP   172.20.42.104    <none>        8000/TCP   8m16s
service/kyverno-cleanup-controller              ClusterIP   172.20.25.127    <none>        443/TCP    8m16s
service/kyverno-cleanup-controller-metrics      ClusterIP   172.20.184.34    <none>        8000/TCP   8m16s
service/kyverno-reports-controller-metrics      ClusterIP   172.20.84.109    <none>        8000/TCP   8m16s
service/kyverno-svc                             ClusterIP   172.20.157.100   <none>        443/TCP    8m16s
service/kyverno-svc-metrics                     ClusterIP   172.20.36.168    <none>        8000/TCP   8m16s
service/policy-reporter                         ClusterIP   172.20.175.164   <none>        8080/TCP   7m53s

NAME                                            READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/kyverno-admission-controller    1/1     1            1           8m16s
deployment.apps/kyverno-background-controller   1/1     1            1           8m16s
deployment.apps/kyverno-cleanup-controller      1/1     1            1           8m16s
deployment.apps/kyverno-reports-controller      1/1     1            1           8m16s
deployment.apps/policy-reporter                 1/1     1            1           7m53s

NAME                                                       DESIRED   CURRENT   READY   AGE
replicaset.apps/kyverno-admission-controller-594c99487b    1         1         1       8m16s
replicaset.apps/kyverno-background-controller-7547578799   1         1         1       8m16s
replicaset.apps/kyverno-cleanup-controller-79575cdb59      1         1         1       8m16s
replicaset.apps/kyverno-reports-controller-8668db7759      1         1         1       8m16s
replicaset.apps/policy-reporter-57f7dfc766                 1         1         1       7m53s

NAME                                                      SCHEDULE       SUSPEND   ACTIVE   LAST SCHEDULE   AGE
cronjob.batch/kyverno-cleanup-admission-reports           */10 * * * *   False     0        3m20s           8m16s
cronjob.batch/kyverno-cleanup-cluster-admission-reports   */10 * * * *   False     0        3m20s           8m16s

NAME                                                           COMPLETIONS   DURATION   AGE
job.batch/kyverno-cleanup-admission-reports-28314690           1/1           13s        3m20s
job.batch/kyverno-cleanup-cluster-admission-reports-28314690   1/1           10s        3m20s
```
