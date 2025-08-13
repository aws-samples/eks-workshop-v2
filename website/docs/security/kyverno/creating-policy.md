---
title: "Creating a Simple Policy"
sidebar_position: 71
---

Kyverno has two kinds of Policy resources: **ClusterPolicy** used for Cluster-Wide Resources and **Policy** used for Namespaced Resources. To gain an understanding of Kyverno policies, we'll start our lab with a simple Pod label requirement. As you may know, labels in Kubernetes are used to tag resources in the cluster.

Below is a sample `ClusterPolicy` which will block any Pod creation that doesn't have the label `CostCenter`:

::yaml{file="manifests/modules/security/kyverno/simple-policy/require-labels-policy.yaml" paths="spec.validationFailureAction,spec.rules,spec.rules.0.match,spec.rules.0.validate,spec.rules.0.validate.message,spec.rules.0.validate.pattern"}

1. `spec.validationFailureAction` tells Kyverno if the resource being validated should be allowed but reported (`Audit`) or blocked (`Enforce`). The default is `Audit`, but in our example it is set to `Enforce`
2. The `rules` section contains one or more rules to be validated
3. The `match` statement sets the scope of what will be checked. In this case, it's any Pod resource
4. The `validate` statement attempts to positively check what is defined. If the statement, when compared with the requested resource, is true, it's allowed. If false, it's blocked
5. The `message` is what gets displayed to a user if this rule fails validation
6. The `pattern` object defines what pattern will be checked in the resource. In this case, it's looking for `metadata.labels` with `CostCenter`

Create the policy using the following command:

```bash
$ kubectl apply -f ~/environment/eks-workshop/modules/security/kyverno/simple-policy/require-labels-policy.yaml

clusterpolicy.kyverno.io/require-labels created
```

Next, take a look at the Pods running in the `ui` Namespace and notice the applied labels:

```bash
$ kubectl -n ui get pods --show-labels
NAME                  READY   STATUS    RESTARTS   AGE   LABELS
ui-67d8cf77cf-d4j47   1/1     Running   0          9m    app.kubernetes.io/component=service,app.kubernetes.io/created-by=eks-workshop,app.kubernetes.io/instance=ui,app.kubernetes.io/name=ui,pod-template-hash=67d8cf77cf
```

Notice that the running Pod doesn't have the required Label, and Kyverno didn't terminate it. This is because Kyverno operates as an `AdmissionController` and won't interfere with resources that already exist in the cluster.

However, if you delete the running Pod, it won't be able to be recreated since it doesn't have the required Label. Go ahead and delete the Pod running in the `ui` Namespace:

```bash
$ kubectl -n ui delete pod --all
pod "ui-67d8cf77cf-d4j47" deleted
$ kubectl -n ui get pods
No resources found in ui namespace.
```

As mentioned, the Pod was not recreated. Try to force a rollout of the `ui` Deployment:

```bash expectError=true
$ kubectl -n ui rollout restart deployment/ui
error: failed to patch: admission webhook "validate.kyverno.svc-fail" denied the request:

resource Deployment/ui/ui was blocked due to the following policies

require-labels:
  autogen-check-team: 'validation error: Label ''CostCenter'' is required to deploy
    the Pod. rule autogen-check-team failed at path /spec/template/metadata/labels/CostCenter/'
```

The rollout failed with the admission webhook denying the request due to the `require-labels` Kyverno Policy.

You can also check this `error` message by describing the `ui` Deployment or viewing the `events` in the `ui` Namespace:

```bash
$ kubectl -n ui describe deployment ui
...
Events:
  Type     Reason             Age                From                   Message
  ----     ------             ----               ----                   -------
  Warning  PolicyViolation    12m (x2 over 9m)   kyverno-scan           policy require-labels/autogen-check-team fail: validation error: Label 'CostCenter' is required to deploy the Pod. rule autogen-check-team failed at path /spec/template/metadata/labels/CostCenter/

$ kubectl -n ui get events | grep PolicyViolation
9m         Warning   PolicyViolation     pod/ui-67d8cf77cf-hvqcd    policy require-labels/check-team fail: validation error: Label 'CostCenter' is required to deploy the Pod. rule check-team failed at path /metadata/labels/CostCenter/
9m         Warning   PolicyViolation     replicaset/ui-67d8cf77cf   policy require-labels/autogen-check-team fail: validation error: Label 'CostCenter' is required to deploy the Pod. rule autogen-check-team failed at path /spec/template/metadata/labels/CostCenter/
9m         Warning   PolicyViolation     deployment/ui              policy require-labels/autogen-check-team fail: validation error: Label 'CostCenter' is required to deploy the Pod. rule autogen-check-team failed at path /spec/template/metadata/labels/CostCenter/
```

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
$ kubectl -n ui get pods --show-labels
NAME                  READY   STATUS    RESTARTS   AGE   LABELS
ui-5498685db8-k57nk   1/1     Running   0          60s   CostCenter=IT,app.kubernetes.io/component=service,app.kubernetes.io/created-by=eks-workshop,app.kubernetes.io/instance=ui,app.kubernetes.io/name=ui,pod-template-hash=5498685db8
```

As you can see, the admission webhook successfully validated the Policy and the Pod was created with the correct Label `CostCenter=IT`!

### Mutating Rules

In the above examples, you checked how Validation Policies work in their default behavior defined in `validationFailureAction`. However, Kyverno can also be used to manage Mutating rules within the Policy, to modify any API Requests to satisfy or enforce the specified requirements on the Kubernetes resources. The resource mutation occurs before validation, so the validation rules will not contradict the changes performed by the mutation section.

Below is a sample Policy with a mutation rule defined:

::yaml{file="manifests/modules/security/kyverno/simple-policy/add-labels-mutation-policy.yaml" paths="spec.rules.0.match,spec.rules.0.mutate"}

1. `match.any.resources.kinds: [Pod]` targets this `ClusterPolicy` to all Pod resources cluster-wide
2.  `mutate` modifies resources during creation (vs. validate which blocks/allows). `patchStrategicMerge.metadata.labels.CostCenter: IT` automatically adds `CostCenter: IT` label to every Pod

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

Validate that the label `CostCenter=IT` was automatically added to the Pod to meet the policy requirements, resulting in a successful Pod creation even though the Deployment didn't have the label specified:

```bash
$ kubectl -n carts get pods --show-labels
NAME                     READY   STATUS    RESTARTS   AGE   LABELS
carts-bb88b4789-kmk62   1/1     Running   0          25s   CostCenter=IT,app.kubernetes.io/component=service,app.kubernetes.io/created-by=eks-workshop,app.kubernetes.io/instance=carts,app.kubernetes.io/name=carts,pod-template-hash=bb88b4789
```

It's also possible to mutate existing resources in your Amazon EKS Clusters with Kyverno Policies using `patchStrategicMerge` and `patchesJson6902` parameters in your Kyverno Policy.

This was just a simple example of labels for our Pods with Validating and Mutating rules. This can be applied to various scenarios such as restricting images from unknown registries, adding data to ConfigMaps, setting tolerations, and much more. In the upcoming labs, you will explore some more advanced use-cases.
