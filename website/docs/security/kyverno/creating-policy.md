---
title: "Creating a Simple Policy"
sidebar_position: 133
---

To get an understanding of Kyverno Policies, we will start our workshop with a Simple Pod Label requirement. Labels in Kubernetes can be used to tag objects & resources in the cluster.

Below we have a Sample policy requiring a Label "CostCenter".

``` yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-labels
spec:
  validationFailureAction: Enforce
  rules:
  - name: check-team
    match:
      any:
      - resources:
          kinds:
          - Pod
    validate:
      message: "Label 'CostCenter' is required to deploy the Pod"
      pattern:
        metadata:
          labels:
            CostCenter: "?*"
```

Kyverno has 2 types of Policies 1/**ClusterPolicy** used for Cluster-Wide Resources & 2/**Policy** used for Namespaced Resources.

1.  In the above example, we have a **ClusterPolicy**, Under the spec section of the Policy, there is a an attribute `validationFailureAction` it tells Kyverno if the resource being validated should be allowed but reported (`Audit`) or blocked (`Enforce`). Defaults to Audit.
2.  The `rules` is one or more rules which must be true.
3.  The `match` statement sets the scope of what will be checked. In this case, it is any `Pod` resource.
4.  The `validate` statement tries to positively check what is defined. If the statement, when compared with the requested resource, is true, it is allowed. If false, it is blocked.
5.  The `message` is what gets displayed to a user if this rule fails validation.
6.  The `pattern` object defines what pattern will be checked in the resource. In this case, it is looking for `metadata.labels` with `CostCenter`.

The Above Example Policy, will block any Pod Creation which doesn't have the label `CostCenter`.

Create a Require_Label_Policy.yaml file containing the Above Sample Policy.

``` shell
$ kubectl create -f Require_Label_Policy.yaml

clusterpolicy.kyverno.io/require-labels created
```

Next we will try to create a `Sample Nginx Pod` without any label `CostCenter`. The Pod Creation will fail, with the admission webhook denying the request due to our `require-labels Kyverno Policy`, with the below output.

``` shell
$ kubectl run nginx --image=nginx:latest

Error from server: admission webhook "validate.kyverno.svc-fail" denied the request:

resource Pod/default/nginx was blocked due to the following policies

require-labels:
  check-team: 'validation error: Label ''CostCenter'' is required to deploy the Pod.
    rule check-team failed at path /metadata/labels/CostCenter/'
```

If we try to create another Sample Pod, for example `Redis` with Label `CostCenter` it should pass the Policy Validation & get successfully created.

``` shell
$ kubectl run redis --image=redis:latest --labels=CostCenter=IT
pod/redis created
```

### Mutating Rules

---

In the above examples, we checked out Validation Policies. Kyverno can also be used to create Mutating Policies to modify any API Requests to Satisfy/enforce the Policy on the object. Resource mutation occurs before validation, so the validation rules should not contradict the changes performed by the mutation section.

Below is the sample mutation policy which we can use to automatically add our label `CostCenter=IT` as default to any `Pod`.

``` yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: add-labels
spec:
  rules:
  - name: add-labels
    match:
      any:
      - resources:
          kinds:
          - Pod
    mutate:
      patchStrategicMerge:
        metadata:
          labels:
            CostCenter: IT
```

You can create a Policy using the above policy yaml, and try creating an Sample Nginx Pod without Labels. The Policy will automatically add a label `CostCenter=IT` to the pod, resulting a successful Pod Creation.

We can also mutate Existing Resources in our EKS Clusters using Kyverno Policies using `patchStrategicMerge` and `patchesJson6902`.

We just went through a simple Example of Labels for our Pods with Validating & Mutating Policies. It can be applied to various scenarios such as Restricting Pod from unknown registries, Adding Data to Config Maps, Adding Tolerations & much more. We will go through some advanced use-cases in the upcoming labs.
