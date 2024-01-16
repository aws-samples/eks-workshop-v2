---
title: "Creating a Simple Policy"
sidebar_position: 133
---

Before start, validate the Kyverno resources provisioned in the last step when you ran the `prepare-environment` script.

You can check the resources created in the Kyverno Namespace as below:

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

To get an understanding of Kyverno Policies, we will start our lab with a Simple Pod Label requirement. Labels in Kubernetes can be used to tag objects & resources in the cluster.

Below we have a Sample policy requiring a Label "CostCenter".

```file 
manifests/modules/security/kyverno/simple-policy/require-labels-policy.yaml
```

Kyverno has 2 kinds of Policy resources, **ClusterPolicy** used for Cluster-Wide Resources and **Policy** used for Namespaced Resources.

1. In the above example, we have a **ClusterPolicy**, Under the spec section of the Policy, there is a an attribute `validationFailureAction` it tells Kyverno if the resource being validated should be allowed but reported (`Audit`) or blocked (`Enforce`). Defaults to Audit.
2. The `rules` is one or more rules which must be true.
3. The `match` statement sets the scope of what will be checked. In this case, it is any `Pod` resource.
4. The `validate` statement tries to positively check what is defined. If the statement, when compared with the requested resource, is true, it is allowed. If false, it is blocked.
5. The `message` is what gets displayed to a user if this rule fails validation.
6. The `pattern` object defines what pattern will be checked in the resource. In this case, it is looking for `metadata.labels` with `CostCenter`.

The Above Example Policy, will block any Pod Creation which doesn't have the label `CostCenter`.

Create a Require_Label_Policy.yaml file containing the Above Sample Policy.

```bash
$ kubectl apply -f https://raw.githubusercontent.com/aws-samples/eks-workshop-v2/main/manifests/modules/security/kyverno/simple-policy/require-labels-policy.yaml

clusterpolicy.kyverno.io/require-labels created
```

Next we will try to create a `Sample Nginx Pod` without any label `CostCenter`. The Pod Creation will fail, with the admission webhook denying the request due to our `require-labels Kyverno Policy`, with the below output.

```shell
$ kubectl run nginx --image=nginx:latest

Error from server: admission webhook "validate.kyverno.svc-fail" denied the request:

resource Pod/default/nginx was blocked due to the following policies

require-labels:
  check-team: 'validation error: Label ''CostCenter'' is required to deploy the Pod.
    rule check-team failed at path /metadata/labels/CostCenter/'
```

If we try to create another Sample Pod, for example `Redis` with Label `CostCenter` it should pass the Policy Validation & get successfully created.

```shell
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
