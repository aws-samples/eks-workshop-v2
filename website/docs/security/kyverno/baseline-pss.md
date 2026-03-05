---
title: "Enforcing Pod Security Standards"
sidebar_position: 72
---

As discussed in the introduction for [Pod Security Standards (PSS)](../pod-security-standards/) section, there are three pre-defined policy levels: **Privileged**, **Baseline**, and **Restricted**. While implementing a Restricted PSS is recommended, it can cause unintended behavior at the application level unless properly configured. To get started, it's recommended to set up a Baseline Policy that will prevent known privileged escalations such as containers accessing HostProcess, HostPath, HostPorts, or allowing traffic snooping. Individual policies can then be set up to restrict or disallow these privileged accesses to containers.

A Kyverno Baseline Policy helps restrict all known privileged escalations under a single policy. It also allows for regular maintenance and updates to incorporate the latest discovered vulnerabilities into the policy.

Privileged containers can perform almost all actions that the host can do and are often used in CI/CD pipelines to allow building and publishing container images. With the now fixed [CVE-2022-23648](https://github.com/containerd/containerd/security/advisories/GHSA-crp2-qrr5-8pq7), a malicious actor could escape the privileged container by exploiting the Control Groups `release_agent` functionality to execute arbitrary commands on the container host.

In this lab, we will create a Deployment with a privileged container on our EKS cluster. Without a policy in place, a Deployment can be freely created and its pod template patched to add privileged access:

```bash hook=baseline-setup
$ kubectl create deployment privileged-deploy --image=public.ecr.aws/nginx/nginx
deployment.apps/privileged-deploy created
$ kubectl patch deployment privileged-deploy --type=json \
  -p='[{"op":"add","path":"/spec/template/spec/containers/0/securityContext","value":{"privileged":true}}]'
deployment.apps/privileged-deploy patched
$ kubectl delete deployment privileged-deploy
deployment.apps "privileged-deploy" deleted
```

The `kubectl patch` command uses a JSON patch to add a `securityContext` to the first container in the pod template, setting `privileged: true`. This grants the container nearly unrestricted access to the host. To prevent such escalated privileged capabilities and avoid unauthorized use of these permissions, it's recommended to set up a Baseline Policy using Kyverno.

The baseline profile of the Pod Security Standards is a collection of the most fundamental and crucial steps that can be taken to secure Pods. Starting from Kyverno 1.8, an entire profile can be assigned to the cluster through a single rule. To learn more about the privileges blocked by the Baseline Profile, please refer to the [Kyverno documentation](https://kyverno.io/policies/#:~:text=Baseline%20Pod%20Security%20Standards,cluster%20through%20a%20single%20rule).

::yaml{file="manifests/modules/security/kyverno/baseline-policy/baseline-policy.yaml" paths="spec.background,spec.validationFailureAction,spec.rules.0.match,spec.rules.0.validate"}

1. `background: true` applies the policy to existing resources in addition to new ones
2. `validationFailureAction: Enforce` blocks non-compliant Deployments from being created or updated
3. `match.any.resources.kinds: [Deployment]` applies the policy to all Deployment resources cluster-wide
4. `allowExistingViolations: false` ensures updates to already-violating Deployments are also blocked
5. `validate.podSecurity` enforces Kubernetes Pod Security Standards at the `baseline` level against the Deployment's pod template, using the `latest` standards version

Go ahead and apply the Baseline Policy:

```bash
$ kubectl apply -f ~/environment/eks-workshop/modules/security/kyverno/baseline-policy/baseline-policy.yaml
clusterpolicy.kyverno.io/baseline-policy created
```

Now, try to create a Deployment with a privileged container. First create the Deployment, then patch it to add `privileged: true` to the pod template:

```bash
$ kubectl create deployment privileged-deploy --image=public.ecr.aws/nginx/nginx
deployment.apps/privileged-deploy created
```

Now try to patch it to add a privileged security context:

```bash expectError=true hook=baseline-blocked
$ kubectl patch deployment privileged-deploy --type=json \
  -p='[{"op":"add","path":"/spec/template/spec/containers/0/securityContext","value":{"privileged":true}}]'
Error from server: admission webhook "validate.kyverno.svc-fail" denied the request:

resource Deployment/default/privileged-deploy was blocked due to the following policies

baseline-policy:
  baseline: 'Validation rule ''baseline'' failed. It violates PodSecurity "baseline:latest":
    (Forbidden reason: privileged, field error list: [spec.template.spec.containers[0].securityContext.privileged
    is forbidden, forbidden values found: true])'
```

As you can see, the patch that adds `privileged: true` to the pod template is blocked because it doesn't comply with our Baseline Policy set on the cluster.

Clean up the Deployment:

```bash
$ kubectl delete deployment privileged-deploy --ignore-not-found=true
deployment.apps "privileged-deploy" deleted
```

