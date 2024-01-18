---
title: "Creating a Simple Policy"
sidebar_position: 133
---

To get an understanding of Kyverno Policies, we will start our lab with a simple Pod Label requirement. As you may know, Labels in Kubernetes can be used to tag objects and resources in the Cluster.

Below we have a sample policy requiring a Label `CostCenter`.

```file
manifests/modules/security/kyverno/simple-policy/require-labels-policy.yaml
```

Kyverno has 2 kinds of Policy resources, **ClusterPolicy** used for Cluster-Wide Resources and **Policy** used for Namespaced Resources. The example above shows a ClusterPolicy. Take sometime to dive deep and check the below details in the configuration.

* Under the spec section of the Policy, there is a an attribute `validationFailureAction` it tells Kyverno if the resource being validated should be allowed but reported `Audit` or blocked `Enforce`. Defaults to Audit, the exaple is set to Enforce.
* The `rules` is one or more rules to be validated.
* The `match` statement sets the scope of what will be checked. In this case, it is any `Pod` resource.
* The `validate` statement tries to positively check what is defined. If the statement, when compared with the requested resource, is true, it is allowed. If false, it is blocked.
* The `message` is what gets displayed to a user if this rule fails validation.
* The `pattern` object defines what pattern will be checked in the resource. In this case, it is looking for `metadata.labels` with `CostCenter`.

The Above Example Policy, will block any Pod Creation which doesn't have the label `CostCenter`.

Create the policy using the following command.

```bash
$ kubectl apply -f https://raw.githubusercontent.com/aws-samples/eks-workshop-v2/main/manifests/modules/security/kyverno/simple-policy/require-labels-policy.yaml

clusterpolicy.kyverno.io/require-labels created
```

Next try to create a sample Pod without any label.

```bash
$ kubectl run nginx --image=nginx:latest

Error from server: admission webhook "validate.kyverno.svc-fail" denied the request:

resource Pod/default/nginx was blocked due to the following policies

require-labels:
  check-team: 'validation error: Label ''CostCenter'' is required to deploy the Pod.
    rule check-team failed at path /metadata/labels/CostCenter/'
```

The Pod creation failed with the admission webhook denying the request due to the  `require-labels` Kyverno Policy.

Now try to create the same sample Pod with the label `CostCenter`.

```bash
$ kubectl run nginx --image=nginx:latest --labels=CostCenter=IT

pod/nginx created

$ kubectl get pods

NAME    READY   STATUS    RESTARTS   AGE
nginx   1/1     Running   0          5m
```

As you can see the admission webhook successfuly validated the Policy and the Pod was created!

### Mutating Rules

In the above examples, you checked how Validation Policies work in their default behavior defined in `validationFailureAction`. However Kyverno can also be used to manage Mutating rules within the Policy, in order to modify any API Requests to satisfy or enforce the specified requirements on the Kubernetes resources. The resource mutation occurs before validation, so the validation rules will not contradict the changes performed by the mutation section.

Below is a sample Policy with a mutation rule defined, which will be used to automatically add our label `CostCenter=IT` as default to any `Pod`.

```file
manifests/modules/security/kyverno/simple-policy/add-labels-mutation-policy.yaml
```

Notice the `mudate` section, under the ClusterPolicy `spec`.

Go ahead, and create the above Policy using the following command.

```bash
$ kubectl apply -f https://raw.githubusercontent.com/aws-samples/eks-workshop-v2/main/manifests/modules/security/kyverno/simple-policy/add-labels-mutation-policy.yaml

clusterpolicy.kyverno.io/add-labels created
```

Try creating another sample Pod without labels.

```bash
$ kubectl run redis --image=redis:latest 

pod/redis created
```

The policy automatically added a label `CostCenter=IT` to the Pod, in order to meet the policy requirements, resulting a successful Pod creation.

```bash
$ kubectl get pods --show-labels
NAME      READY   STATUS    RESTARTS   AGE   LABELS
nginx     1/1     Running   0          9m   CostCenter=IT
redis     1/1     Running   0          2m   CostCenter=IT,run=redis
```

It's also possible to mutate existing resources in your Amazon EKS Clusters with Kyverno Policies using `patchStrategicMerge` and `patchesJson6902` parameters in your Kyverno Policy.

This was just a simple example of Labels for our Pods with Validating and Mutating rules. This can be applied to various scenarios such as restricting Images from unknown registries, adding Data to Config Maps, Tolerations and much more. In the next upcoming labs, you will go through some more advanced use-cases.

Run the following command to cleanup the Pod resources created on this lab.

```bash
$ kubectl delete pod nginx redis
pod "nginx" deleted
pod "redis" deleted
```
