---
title: "Creating a Simple Policy"
sidebar_position: 71
---

Kyverno has two kinds of Policy resources: **ClusterPolicy** used for Cluster-Wide Resources and **Policy** used for Namespaced Resources. To gain an understanding of Kyverno policies, we'll start our lab with a label requirement on Deployments.

Below is a sample `ClusterPolicy` which will block any Deployment whose pod template doesn't have the label `CostCenter`:

::yaml{file="manifests/modules/security/kyverno/simple-policy/require-labels-policy.yaml" paths="spec.validationFailureAction,spec.rules,spec.rules.0.match,spec.rules.0.validate,spec.rules.0.validate.allowExistingViolations,spec.rules.0.validate.message,spec.rules.0.validate.pattern"}

1. `spec.validationFailureAction` tells Kyverno if the resource being validated should be allowed but reported (`Audit`) or blocked (`Enforce`). The default is `Audit`, but in our example it is set to `Enforce`
2. The `rules` section contains one or more rules to be validated
3. The `match` statement sets the scope of what will be checked. In this case, it's any `Deployment` resource
4. The `validate` statement attempts to positively check what is defined. If the statement, when compared with the requested resource, is true, it's allowed. If false, it's blocked
5. `allowExistingViolations: false` ensures that updates to already-violating Deployments are also blocked. By default, Kyverno allows updates to pre-existing non-compliant resources to avoid disrupting workloads that existed before the policy was applied — setting this to `false` closes that gap and enforces the policy strictly on all admission requests
6. The `message` is what gets displayed to a user if this rule fails validation
7. The `pattern` object defines what pattern will be checked in the resource. In this case, it's looking for `spec.template.metadata.labels` with `CostCenter` — the pod template labels inside the Deployment spec

Create the policy using the following command:

```bash
$ kubectl apply -f ~/environment/eks-workshop/modules/security/kyverno/simple-policy/require-labels-policy.yaml

clusterpolicy.kyverno.io/require-labels created
```

Next, take a look at the `ui` Deployment and notice its pod template labels:

```bash
$ kubectl -n ui get deployment ui -o jsonpath='{.spec.template.metadata.labels}' | jq
{
  "app.kubernetes.io/component": "service",
  "app.kubernetes.io/created-by": "eks-workshop",
  "app.kubernetes.io/instance": "ui",
  "app.kubernetes.io/name": "ui"
}
```

The pod template is missing the required `CostCenter` label. Now try to force a rollout of the `ui` Deployment:

```bash hook=labels-blocked expectError=true
$ kubectl -n ui rollout restart deployment/ui
error: failed to patch: admission webhook "validate.kyverno.svc-fail" denied the request:

resource Deployment/ui/ui was blocked due to the following policies

require-labels:
  check-team: 'validation error: Label ''CostCenter'' is required on the Deployment
    pod template. rule check-team failed at path /spec/template/metadata/labels/CostCenter/'
```

The rollout failed with the admission webhook denying the request due to the require-labels Kyverno Policy.

Now add the required label `CostCenter` to the `ui` Deployment, using the Kustomization patch below:

```kustomization
modules/security/kyverno/simple-policy/ui-labeled/deployment.yaml
Deployment/ui
```

```bash
$ kubectl apply -k ~/environment/eks-workshop/modules/security/kyverno/simple-policy/ui-labeled
namespace/ui unchanged
serviceaccount/ui unchanged
configmap/ui unchanged
service/ui unchanged
deployment.apps/ui configured
$ kubectl -n ui rollout status deployment/ui
deployment "ui" successfully rolled out
$ kubectl -n ui get deployment ui -o jsonpath='{.spec.template.metadata.labels}' | jq
{
  "CostCenter": "IT",
  "app.kubernetes.io/component": "service",
  "app.kubernetes.io/created-by": "eks-workshop",
  "app.kubernetes.io/instance": "ui",
  "app.kubernetes.io/name": "ui"
}
```

The policy was satisfied and the rollout succeeded.

### Mutating Rules

In the above examples, you checked how Validation Policies work in their default behavior defined in `validationFailureAction`. However, Kyverno can also be used to manage Mutating rules within the Policy, to modify any API Requests to satisfy or enforce the specified requirements on the Kubernetes resources. The resource mutation occurs before validation, so the validation rules will not contradict the changes performed by the mutation section.

Below is a sample Policy with a mutation rule defined:

::yaml{file="manifests/modules/security/kyverno/simple-policy/add-labels-mutation-policy.yaml" paths="spec.rules.0.match,spec.rules.0.mutate"}

1. `match.any.resources.kinds: [Deployment]` targets this `ClusterPolicy` to all Deployment resources cluster-wide
2. `mutate` modifies resources during creation (vs. validate which blocks/allows). `patchStrategicMerge.spec.template.metadata.labels.CostCenter: IT` automatically adds `CostCenter: IT` to the pod template labels of every Deployment

Go ahead and create the above Policy using the following command:

```bash
$ kubectl apply -f  ~/environment/eks-workshop/modules/security/kyverno/simple-policy/add-labels-mutation-policy.yaml

clusterpolicy.kyverno.io/add-labels created
```

To validate the Mutation Webhook, let's roll out the `carts` Deployment without explicitly adding a label:

```bash
$ kubectl -n carts rollout restart deployment/carts
deployment.apps/carts restarted
$ kubectl -n carts rollout status deployment/carts
deployment "carts" successfully rolled out
```

Validate that the label `CostCenter=IT` was automatically added to the `carts` Deployment pod template to meet the policy requirements:

```bash
$ kubectl -n carts get deployment carts -o jsonpath='{.spec.template.metadata.labels}' | jq
{
  "CostCenter": "IT",
  "app.kubernetes.io/component": "service",
  "app.kubernetes.io/created-by": "eks-workshop",
  "app.kubernetes.io/instance": "carts",
  "app.kubernetes.io/name": "carts"
}
```

The label was automatically injected into the pod template of the `carts` Deployment. It's also possible to mutate existing resources in your Amazon EKS Clusters with Kyverno Policies using `patchStrategicMerge` and `patchesJson6902` parameters in your Kyverno Policy.

This was just a simple example of validating and mutating Deployments with Kyverno. In the upcoming labs, you will explore more advanced use-cases such as enforcing Pod Security Standards and restricting container image registries.
