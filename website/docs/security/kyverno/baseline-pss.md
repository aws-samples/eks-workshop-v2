---
title: "Enforcing Pod Security Standards"
sidebar_position: 72
---

As discussed in the introduction for [Pod Security Standards (PSS)](../pod-security-standards/) section, there are three pre-defined policy levels: **Privileged**, **Baseline**, and **Restricted**. While implementing a Restricted PSS is recommended, it can cause unintended behavior at the application level unless properly configured. To get started, it's recommended to set up a Baseline Policy that will prevent known privileged escalations such as containers accessing HostProcess, HostPath, HostPorts, or allowing traffic snooping. Individual policies can then be set up to restrict or disallow these privileged accesses to containers.

A Kyverno Baseline Policy helps restrict all known privileged escalations under a single policy. It also allows for regular maintenance and updates to incorporate the latest discovered vulnerabilities into the policy.

Privileged containers can perform almost all actions that the host can do and are often used in CI/CD pipelines to allow building and publishing container images. With the now fixed [CVE-2022-23648](https://github.com/containerd/containerd/security/advisories/GHSA-crp2-qrr5-8pq7), a malicious actor could escape the privileged container by exploiting the Control Groups `release_agent` functionality to execute arbitrary commands on the container host.

In this lab, we will run a privileged Pod on our EKS cluster. Execute the following command:

```bash
$ kubectl run privileged-pod --image=nginx --restart=Never --privileged
pod/privileged-pod created
$ kubectl delete pod privileged-pod
pod "privileged-pod" deleted
```

To prevent such escalated privileged capabilities and avoid unauthorized use of these permissions, it's recommended to set up a Baseline Policy using Kyverno.

The baseline profile of the Pod Security Standards is a collection of the most fundamental and crucial steps that can be taken to secure Pods. Starting from Kyverno 1.8, an entire profile can be assigned to the cluster through a single rule. To learn more about the privileges blocked by the Baseline Profile, please refer to the [Kyverno documentation](https://kyverno.io/policies/#:~:text=Baseline%20Pod%20Security%20Standards,cluster%20through%20a%20single%20rule).

::yaml{file="manifests/modules/security/kyverno/baseline-policy/baseline-policy.yaml" paths="spec.background,spec.validationFailureAction,spec.rules.0.match,spec.rules.0.validate"}

1. `background: true` applies the policy to existing resources in addition to new ones
2. `validationFailureAction: Enforce` blocks non-compliant Pods from being created
3. `match.any.resources.kinds: [Pod]` applies the policy to all Pod resources cluster-wide
4. `validate.podSecurity` enforces Kubernetes Pod Security Standards at the `baseline` level with moderate security restrictions using the `latest` standards version

Go ahead and apply the Baseline Policy:

```bash
$ kubectl apply -f ~/environment/eks-workshop/modules/security/kyverno/baseline-policy/baseline-policy.yaml
clusterpolicy.kyverno.io/baseline-policy created
```

Now, try to run the privileged Pod again:

```bash expectError=true
$ kubectl run privileged-pod --image=nginx --restart=Never --privileged
Error from server: admission webhook "validate.kyverno.svc-fail" denied the request:

resource Pod/default/privileged-pod was blocked due to the following policies

baseline-policy:
  baseline: |
    Validation rule 'baseline' failed. It violates PodSecurity "baseline:latest": ({Allowed:false ForbiddenReason:privileged ForbiddenDetail:container "privileged-pod" must not set securityContext.privileged=true})
```

As you can see, the creation failed because it doesn't comply with our Baseline Policy set on the cluster.

### Note on Auto-Generated Policies

Pod Security Admission (PSA) operates at the Pod level, but in practice, Pods are usually managed by Pod controllers like Deployments. Having no indication of Pod security errors at the Pod controller level can make issues complex to troubleshoot. The PSA enforce mode is the only PSA mode that prevents Pods from being created; however, PSA enforcement doesn't act at the Pod controller level. To improve this experience, it's recommended that PSA `warn` and `audit` modes are also used with `enforce`. This way, PSA will indicate that the controller resources are trying to create Pods that would fail with the applied PSS level.

Using Policy-as-Code (PaC) solutions with Kubernetes presents another challenge of writing and maintaining policies to cover all the different resources used within clusters. With the [Kyverno Auto-Gen Rules for Pod Controllers](https://kyverno.io/docs/writing-policies/autogen/) feature, the Pod policies auto-generate associated Pod controller (Deployment, DaemonSet, etc.) policies. This Kyverno feature enhances the expressive nature of policies and reduces the effort to maintain policies for associated resources, improving the PSA user experience where controller resources are not prevented from progressing while the underlying Pods are.
