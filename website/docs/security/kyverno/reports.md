---
title : "Policy Reports in Kyverno"
weight : 137
---

Kyverno includes [policy reporting](https://kyverno.io/docs/policy-reports/), using the open format defined by the Kubernetes Policy Working Group. Kyverno emits these policy reports when admission actions (CREATE, UPDATE, DELETE) are performed. These reports are also generated as a result of background scans that apply policies on existing resources. 

Policy reports are Kubernetes Custom resources, and in our case it is managed by Kyverno. So far, in the workshop we have created a couple of Policy reports. They are created for specific rules, when a resource is matched by one or more rules according to the policy definition & violate multiple rules, there will be multiple entries. When resources are deleted, their entry will be removed from the report. Reports, therefore, always represent the current state of the cluster and do not record historical information.

For example, if a validate policy in ```Audit``` mode exists containing a single rule which requires that all resources set the label ```CostCenter``` and a user creates a Pod which does not set the team label, Kyverno will allow the Pod’s creation but record it as a fail result in a policy report due to the Pod being in violation of the policy and rule. Policies configured with ```spec.validationFailureAction: Enforce``` immediately block violating resources and results will only be reported for pass evaluations.

Now, we will check on our cluster's status on compliance with the policies we have created so far in this workshop. We will run the below command, to get a overview of the Kyverno policy reports:

:::code{showCopyAction=true showLineNumbers=true}
kubectl get policyreports -A
:::

Sample Output should be as below, the number of policies might differ & we can ignore the same.

:::code{}
NAMESPACE         NAME                                PASS   FAIL   WARN   ERROR   SKIP   AGE
default           cpol-baseline-policy                1      1      0      0       0      6d21h
default           cpol-podsecurity-subrule-baseline   1      1      0      0       0      6d21h
default           cpol-restrict-image-registries      0      2      0      0       0      22s
default           cpol-verify-image                   1      0      0      0       0      22s
karpenter         cpol-baseline-policy                4      0      0      0       0      6d21h
karpenter         cpol-podsecurity-subrule-baseline   4      0      0      0       0      6d21h
karpenter         cpol-restrict-image-registries      0      4      0      0       0      22s
kube-system       cpol-baseline-policy                4      4      0      0       0      6d21h
kube-system       cpol-podsecurity-subrule-baseline   4      6      0      0       0      6d21h
kube-system       cpol-restrict-image-registries      0      10     0      0       0      22s
kyverno           cpol-baseline-policy                14     0      0      0       0      6d21h
kyverno           cpol-podsecurity-subrule-baseline   18     0      0      0       0      6d21h
kyverno           cpol-restrict-image-registries      0      18     0      0       0      22s
policy-reporter   cpol-baseline-policy                3      0      0      0       0      6d18h
policy-reporter   cpol-podsecurity-subrule-baseline   3      0      0      0       0      6d18h
policy-reporter   cpol-restrict-image-registries      0      3      0      0       0      22s
:::

In the above output, we can see a number of policies that we created such as **verify-image**, **baseline-policy**, **restrict-image-registries**. You can also see the status of objects such as **Pass**, **Fail**, **WARN**, **ERROR**, **SKIP**. 

To check in detail on the violations for a policy, we can run the below command. In our case, we will select **cpol-restrict-image-registries**, But you can select any other policy as well.

:::code{showCopyAction=true showLineNumbers=true}
kubectl get policyreports cpol-restrict-image-registries -o yaml
:::

Sample Output:

:::code{language=yaml highlightLines=33-40,50-56}
apiVersion: wgpolicyk8s.io/v1alpha2
kind: PolicyReport
metadata:
  creationTimestamp: "2023-09-30T06:48:52Z"
  generation: 2
  labels:
    app.kubernetes.io/managed-by: kyverno
    cpol.kyverno.io/restrict-image-registries: "4035625"
  managedFields:
  - apiVersion: wgpolicyk8s.io/v1alpha2
    fieldsType: FieldsV1
    fieldsV1:
      f:metadata:
        f:labels:
          .: {}
          f:app.kubernetes.io/managed-by: {}
          f:cpol.kyverno.io/restrict-image-registries: {}
      f:results: {}
      f:summary:
        .: {}
        f:error: {}
        f:fail: {}
        f:pass: {}
        f:skip: {}
        f:warn: {}
    manager: reports-controller
    operation: Update
    time: "2023-09-30T06:52:20Z"
  name: cpol-restrict-image-registries
  namespace: default
  resourceVersion: "4037090"
  uid: f4e013c4-f79b-498f-8792-f3d8fc6cc32e
results:
- message: 'validation error: Unknown Image registry. rule validate-registries failed
    at path /spec/containers/0/image/'
  policy: restrict-image-registries
  resources:
  - apiVersion: v1
    kind: Pod
    name: signed
    namespace: default
    uid: 07f09b25-9ed7-4237-a615-084fff26307f
  result: fail
  rule: validate-registries
  scored: true
  source: kyverno
  timestamp:
    nanos: 0
    seconds: 1696056503
- message: 'validation error: Unknown Image registry. rule validate-registries failed
    at path /spec/containers/0/image/'
  policy: restrict-image-registries
  resources:
  - apiVersion: v1
    kind: Pod
    name: privileged-pod
    namespace: default
    uid: a0aa2205-4ca6-4fea-8b32-c8a1296e9f57
  result: fail
  rule: validate-registries
  scored: true
  source: kyverno
  timestamp:
    nanos: 0
    seconds: 1696056710
summary:
  error: 0
  fail: 2
  pass: 0
  skip: 0
  warn: 0
  :::

As we can see in the above output, Our Pods namely Privileged-Pod & Signed failed the rules for our policy ```restrict-image-registries```. Monitoring reports in this way could be an overhead for administrators. Kyverno also supports a GUI based tool namely [Policy reporter](https://github.com/kyverno/policy-reporter#readme). This is outside of this workshop's scope., but can be tried in the workshop accounts.

