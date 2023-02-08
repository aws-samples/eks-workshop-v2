---
title: "Pod Security Standards"
sidebar_position: 50
sidebar_custom_props: {"module": true}
---

:::tip Before you start
Prepare your environment for this section:

```bash timeout=300 wait=30
$ reset-environment 
```

:::

Securely adopting Kubernetes includes preventing unwanted changes to clusters. Unwanted changes can disrupt cluster operations, workload behaviors, and even compromise the whole environment integrity. Introducing Pods that lack correct security configurations is an example of an unwanted cluster change. To control Pod security Kubernetes provided [Pod Security Policy / PSP](https://kubernetes.io/docs/concepts/policy/pod-security-policy/) resources. PSPs specify a set of security settings that Pods must meet before they can be created or updated in a cluster. However, as of Kubernetes version 1.21, PSPs have been deprecated, and are scheduled for removal in Kubernetes version 1.25. 

In Kubernetes, PSPs are being replaced with, [Pod Security Admission / PSA](https://kubernetes.io/docs/concepts/security/pod-security-admission/), a built-in admission controller that implements the security controls outlined in the [Pod Security Standards / PSS](https://kubernetes.io/docs/concepts/security/pod-security-standards/). As of Kubernetes version 1.23, PSA and PSS have both reached beta feature states, and are enabled in Amazon Elastic Kubernetes Service (EKS) by default.

### Pod Security Standards (PSS) and Pod Security Admission (PSA)

According to the Kubernetes documentation, the PSS "define three different policies to broadly cover the security spectrum. These policies are cumulative and range from highly-permissive to highly-restrictive." 

The policy levels are defined as:

* **Privileged:** Unrestricted (unsecure) policy, providing the widest possible level of permissions. This policy allows for known privilege escalations. It's the absence of a policy. This is good for applications such as logging agents, CNIs, storage drivers, and other system wide applications that need privileged access.
* **Baseline:** Minimally restrictive policy which prevents known privilege escalations. Allows the default (minimally specified) Pod configuration. The baseline policy prohibits use of hostNetwork, hostPID, hostIPC, hostPath, hostPort, the inability to add Linux capabilities, along with several other restrictions. 
* **Restricted:*** Heavily restricted policy, following current Pod hardening best practices. This policy inherits from the baseline and adds further restrictions such as the inability to run as root or a root-group. Restricted policies may impact an application's ability to function. They are primarily targeted at running security critical applications.

The PSA admission controller implements the controls, outlined by the PSS policies, via three modes of operation, listed below.

* **enforce:** Policy violations will cause the Pod to be rejected.
* **audit:** Policy violations will trigger the addition of an audit annotation to the event recorded in the [audit log](https://kubernetes.io/docs/tasks/debug/debug-cluster/audit/), but are otherwise allowed.
* **warn:** Policy violations will trigger a user-facing warning, but are otherwise allowed.

### Built-in Pod Security admission enforcement

From Kubernetes version 1.23, the PodSecurity [feature gate](https://kubernetes.io/docs/reference/command-line-tools-reference/feature-gates/) is enabled by default in Amazon EKS. The default [PSS and PSA settings](https://kubernetes.io/docs/tasks/configure-pod-container/enforce-standards-admission-controller/#configure-the-admission-controller) for upstream Kubernetes version 1.23 are also used for Amazon EKS, as listed below.

> *PodSecurity feature gate is in Beta version (apiVersion: v1beta1) on Kubernetes v1.23 and v1.24, and became Generally Available (GA,  apiVersion: v1) in Kubernetes v1.25.*

```yaml
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

* No PSA exemptions are configured at Kubernetes API server startup.
* The Privileged PSS profile is configured by default for all PSA modes, and set to latest versions.

### Pod Security Admission labels for Namespaces 

Given the above default configuration, you must configure specific PSS profiles and PSA modes at the Kubernetes Namespace level, to opt Namespaces into Pod security provided by the PSA and PSS. You can configure Namespaces to define the admission control mode you want to use for Pod security. With [Kubernetes labels](https://kubernetes.io/docs/concepts/overview/working-with-objects/labels), you can choose which of the predefined PSS levels you want to use for Pods in a given Namespace. The label you select defines what action the PSA takes if a potential violation is detected. As seen below, you can configure any or all modes, or even set a different level for different modes. For each mode, there are two possible labels that determine the policy used.

```
# The per-mode level label indicates which policy level to apply for the mode.
#
# MODE must be one of `enforce`, `audit`, or `warn`.
# LEVEL must be one of `privileged`, `baseline`, or `restricted`.
*pod-security.kubernetes.io/<MODE>*: <LEVEL>

# Optional: per-mode version label that can be used to pin the policy to the
# version that shipped with a given Kubernetes minor version (for example v1.24).
#
# MODE must be one of `enforce`, `audit`, or `warn`.
# VERSION must be a valid Kubernetes minor version, or `latest`.
*pod-security.kubernetes.io/<MODE>-version*: <VERSION>
```

Below is an example of PSA and PSS Namespace configurations that can be used for testing. Note that we did not include the optional PSA mode-version label. We used the cluster-wide setting, latest, configured by default. By uncommenting the desired labels, below, you can enable the PSA modes and PSS profiles you need for your respective Namespace.

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: psa-pss-test-ns
  labels:    
    # pod-security.kubernetes.io/enforce: privileged
    # pod-security.kubernetes.io/audit: privileged
    # pod-security.kubernetes.io/warn: privileged
    
    # pod-security.kubernetes.io/enforce: baseline
    # pod-security.kubernetes.io/audit: baseline
    # pod-security.kubernetes.io/warn: baseline
    
    # pod-security.kubernetes.io/enforce: restricted
    # pod-security.kubernetes.io/audit: restricted
    # pod-security.kubernetes.io/warn: restricted
      
```

### Validating Admission Controllers 

In Kubernetes, an Admission Controller is a piece of code that intercepts requests to the Kubernetes API server before they are persisted into etcd, and used to make cluster changes. Admission controllers can be of  type mutating, validating, or both. The implementation of PSA is a validating admission controller, and it checks inbound Pod specification requests for conformance to the specified PSS. 

In the flow below, [mutating and validating dynamic admission controllers](https://kubernetes.io/docs/reference/access-authn-authz/extensible-admission-controllers/), a.k.a. admission webhooks, are integrated to the Kubernetes API server request flow, via webhooks. These webhooks call out to services, configured to respond to certain types of API server requests. For example, you can use webhooks to configure dynamic admission controllers to validate that containers in a Pod are running as non-root users, or containers are sourced from trusted registries. 

![](k8s-admission-controllers.png)

### Using PSA and PSS 

PSA enforces the policies outlined in PSS, and the PSS policies define a set of Pod security profiles. In the diagram below, we outline how PSA and PSS work together, with Pods and Namespaces, to define Pod security profiles and apply admission control based on those profiles. As seen in the diagram below, the PSA enforcement modes and PSS policies are defined as labels in the target Namespaces.

![](using-pss-psa.png)
