---
title: "Managing Pod Security on Amazon EKS with Kyverno"
sidebar_position: 130
sidebar_custom_props: {"module": true}
---

As containers are used in cloud native production environments, DevOps and security teams need to gain real-time visibility into container activity, restrict container access to host and network resources, and detect and prevent exploits and attacks on running containers.

Introducing Pods that lack correct security configurations in a cluster, is an example of an unwanted change, which can disrupt cluster operations. To control Pod security Kubernetes provide (starting on version 1.23) [Pod Security Admission (PSA)](https://kubernetes.io/docs/concepts/security/pod-security-admission/) , a built-in admission controller that implements the security controls outlined in the [Pod Security Standards (PSS)](https://kubernetes.io/docs/concepts/security/pod-security-standards/) , enabled in Amazon Elastic Kubernetes Service (EKS) by default.

### Pod Security Standards (PSS) and Pod Security Admission (PSA)

According to [the Kubernetes documentation](https://v1-23.docs.kubernetes.io/docs/concepts/security/pod-security-standards/), the PSS "define three different policies to broadly cover the security spectrum. These policies are cumulative and range from highly-permissive to highly-restrictive." The policy levels are defined as:

**Privileged:** Unrestricted (unsecure) policy, providing the widest possible level of permissions. This policy allows for known privilege escalations. It is the absence of a policy. This is good for applications such as logging agents, CNIs, storage drivers, and other system wide applications that need privileged access.

**Baseline:** Minimally restrictive policy which prevents known privilege escalations. Allows the default (minimally specified) Pod configuration. The baseline policy prohibits use of hostNetwork, hostPID, hostIPC, hostPath, hostPort, the inability to add Linux capabilities, along with several other restrictions.

**Restricted:** Heavily restricted policy, following current Pod hardening best practices. This policy inherits from the baseline and adds further restrictions such as the inability to run as root or a root-group. Restricted policies may impact an application's ability to function. They are primarily targeted at running security critical applications.

PSA is a Kubernetes in-tree admission controller to enforce:

>"…requirements on a Pod's Security Context and other related fields according to the three levels defined by the Pod Security Standards” – Kubernetes Documentation

The PSA admission controller implements the controls, outlined by the PSS profiles, via three modes of operation:

- **enforce:** Policy violations will cause the pod to be rejected.

- **audit:** Policy violations trigger the addition of an audit annotation to the event recorded in the audit log, but are otherwise allowed.

- **warn:** Policy violations will trigger a user-facing warning, but are otherwise allowed.

In the following diagram, we outline how PSA and PSS work together, with pods and namespaces, to define pod security profiles and apply admission control based on those profiles. As seen in the following diagram, the PSA enforcement modes and PSS policies are defined as labels in the target Namespaces.

![PSS-PSA-Image](/assets/psa-pss.jpeg)

### Default PSA and PSS settings
The default (cluster-wide) settings for PSA and PSS are seen below.

> Note: These settings can not be changed (customized) at the Kubernetes API server for Amazon EKS.

```
defaults:
  enforce: "privileged"
  enforce-version: "latest"
  audit: "privileged"
  audit-version: "latest"
  warn: "privileged"
  warn-version: "latest"
exemptions:
  # Array of authenticated usernames to exempt.
  usernames: []
  # Array of runtime class names to exempt.
  runtimeClasses: []
  # Array of namespaces to exempt.
  namespaces: []
```

The above settings configure the following cluster-wide scenario:

- No PSA exemptions are configured at Kubernetes API server startup.
- The Privileged PSS profile is configured by default for all PSA modes, and set to latest versions.
- Namespaces are opted into more restrictive PSS policies via labels.

---

Till now we have covered on a brief on PSA & PSS for Kubernetes workloads. By the end of this workshop, you will have gained familiarity with approaches to Manage Pod Level Security using the aforementioned concepts via implementing [Kyverno](https://kyverno.io/docs/) on Amazon EKS. You will also have hands-on experience with approaches that you can bring back to your organization.

### Target audience
These workshops assume you have some familiarity with Amazon EKS & Kubernetes and are interested in learning more about applying Security solutions to modern applications.

- Architects
- Security Architects
- Governance Professionals

Coding experience is not required for this workshop. Any code, configuration, or commands required are provided.


This workshop is designed to run in AWS Workshop Studio in us-east-1.

### Summary

In this workshop, we will go through the below Agenda:

- Installation of Kyverno on the EKS Cluster

Labs:
---
- Creating a Simple Policy for Validation & Mutation of Pod Labels
- Restricting Image Registries
- Baselining Pod Security Standards
- Supply Chain Security(Image Signing & Verification) on Amazon EKS using AWS KMS & CoSign with Kyverno
- Policy Reports
- Kyverno CLI