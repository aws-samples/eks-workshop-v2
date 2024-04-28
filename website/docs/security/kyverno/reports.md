---
title: "Reports & Auditing"
sidebar_position: 74
---

Kyverno also includes a [Policy Reporting](https://kyverno.io/docs/policy-reports/) tool, using the open format defined by the Kubernetes Policy Working Group and deployed as custom resources in the cluster. Kyverno emits these reports when admission actions like _CREATE_, _UPDATE_, and _DELETE_ are performed in the cluster, they are also generated as a result of background scans that validate policies on already existing resources.

So far in the workshop we have created a few Policies for specific rules. When a resource is matched by one or more rules according to the policy definition and violate any of them, an entry will be created in the report for each violation, resulting in multiple entries if the same resources matches and violate multiple rules. When resources are deleted their entry will be removed from the reports, meaning that Kyverno Reports will always represent the current state of the cluster and do not record historical information.

As seen earlier, Kyverno has two types of `validationFailureAction`, `Audit` mode that will allow resouces to be created, and report the action in the Policy Reports, or `Enforce` which will deny the resource creation, but also not add an entry in the Policy Reports. For example, if a Policy in `Audit` mode contain a single rule which requires all resources to set the label `CostCenter` and a Pod is created without the that, Kyverno will allow the Pod’s creation but record it as a `FAIL` result in a Policy Report due the rule violation. If this same Policy is configured with `Enforce` mode, Kyverno will immediately block the resource creation and this will not generate an entry in the Policy Reports, however if the Pod is created in compliance with the rule, it will be reported as `PASS` in the report. It is possible to check blocked actions in the Kubernetes events for the Namespace where the action was requested.

Now, we will check on our cluster's status on compliance with the policies we have created so far in this workshop with an overview of the Policy Reports generated.

```bash hook=reports
$ kubectl get policyreports -A

NAMESPACE     NAME                             PASS   FAIL   WARN   ERROR   SKIP   AGE
assets        cpol-baseline-policy             3      0      0      0       0      19m
assets        cpol-require-labels              0      3      0      0       0      27m
assets        cpol-restrict-image-registries   3      0      0      0       0      25m
carts         cpol-baseline-policy             6      0      0      0       0      19m
carts         cpol-require-labels              0      6      0      0       0      27m
carts         cpol-restrict-image-registries   3      3      0      0       0      25m
catalog       cpol-baseline-policy             5      0      0      0       0      19m
catalog       cpol-require-labels              0      5      0      0       0      27m
catalog       cpol-restrict-image-registries   5      0      0      0       0      25m
checkout      cpol-baseline-policy             6      0      0      0       0      19m
checkout      cpol-require-labels              0      6      0      0       0      27m
checkout      cpol-restrict-image-registries   6      0      0      0       0      25m
default       cpol-baseline-policy             2      0      0      0       0      19m
default       cpol-require-labels              2      0      0      0       0      13m
default       cpol-restrict-image-registries   1      1      0      0       0      13m
kube-system   cpol-baseline-policy             4      8      0      0       0      19m
kube-system   cpol-require-labels              0      12     0      0       0      27m
kube-system   cpol-restrict-image-registries   0      12     0      0       0      25m
kyverno       cpol-baseline-policy             24     0      0      0       0      19m
kyverno       cpol-require-labels              0      24     0      0       0      27m
kyverno       cpol-restrict-image-registries   0      24     0      0       0      25m
orders        cpol-baseline-policy             6      0      0      0       0      19m
orders        cpol-require-labels              0      6      0      0       0      27m
orders        cpol-restrict-image-registries   6      0      0      0       0      25m
rabbitmq      cpol-baseline-policy             2      0      0      0       0      19m
rabbitmq      cpol-require-labels              0      2      0      0       0      27m
rabbitmq      cpol-restrict-image-registries   2      0      0      0       0      25m
ui            cpol-baseline-policy             3      0      0      0       0      19m
ui            cpol-require-labels              0      3      0      0       0      27m
ui            cpol-restrict-image-registries   3      0      0      0       0      25m
```

> The output may vary.

Because we worked with just ClusterPolicies, you can see in the above output a number of Reports that were generated across all Namespaces, such as `cpol-verify-image`, `cpol-baseline-policy`, and `cpol-restrict-image-registries` and not just in the `default` Namespace, where we created the resources to be validated. You can also see the status of objects such as `PASS`, `FAIL`, `WARN`, `ERROR`, and `SKIP`.

As mentioned earlier, the blocked actions will reside in the Namespace events, take a look on those using the command below.

```bash
$ kubectl get events | grep block
8m         Warning   PolicyViolation   clusterpolicy/restrict-image-registries   Pod default/nginx-public: [validate-registries] fail (blocked); validation error: Unknown Image registry. rule validate-registries failed at path /spec/containers/0/image/
3m         Warning   PolicyViolation   clusterpolicy/restrict-image-registries   Pod default/nginx-public: [validate-registries] fail (blocked); validation error: Unknown Image registry. rule validate-registries failed at path /spec/containers/0/image/
```

> The output may vary.

Now, take a closer look in the Policy Reports for the `default` Namespace used in the labs.

```bash
$ kubectl get policyreports
NAME                                           PASS   FAIL   WARN   ERROR   SKIP   AGE
default       cpol-baseline-policy             2      0      0      0       0      19m
default       cpol-require-labels              2      0      0      0       0      13m
default       cpol-restrict-image-registries   1      1      0      0       0      13m
```

Check that for the `restrict-image-registries` ClusterPolicy we have just one `FAIL` and one `PASS` reports. This happened because all the ClusterPolicies were created with `Enforce` mode, and as mentioned the blocked resources are not reported, also the previously running resources that could violate policy rules, were already removed.

The `nginx` Pod, that we left running with a publicly available image, is the only remaining resource that violates the `restrict-image-registries` policy, and it's shown in the report.

Check that in more detail the violations for this Policy, by describing a specific report. As shown in the example below, use the `kubectl describe` command for the `cpol-restrict-image-registries` Report to see the validation results for the `restrict-image-registries` ClusterPolicy.

```bash
$ kubectl describe policyreport cpol-restrict-image-registries
Name:         cpol-restrict-image-registries
Namespace:    default
Labels:       app.kubernetes.io/managed-by=kyverno
              cpol.kyverno.io/restrict-image-registries=607025
Annotations:  <none>
API Version:  wgpolicyk8s.io/v1alpha2
Kind:         PolicyReport
Metadata:
  Creation Timestamp:  2024-01-18T01:03:40Z
  Generation:          1
  Resource Version:    607320
  UID:                 7abb6c11-9610-4493-ab1e-df94360ce773
Results:
  Message:  validation error: Unknown Image registry. rule validate-registries failed at path /spec/containers/0/image/
  Policy:   restrict-image-registries
  Resources:
    API Version:  v1
    Kind:         Pod
    Name:         nginx
    Namespace:    default
    UID:          dd5e65a9-66b5-4192-89aa-a291d150807d
  Result:         fail
  Rule:           validate-registries
  Scored:         true
  Source:         kyverno
  Timestamp:
    Nanos:    0
    Seconds:  1705539793
  Message:    validation rule 'validate-registries' passed.
  Policy:     restrict-image-registries
  Resources:
    API Version:  v1
    Kind:         Pod
    Name:         nginx-ecr
    Namespace:    default
    UID:          e638aad7-7fff-4908-bbe8-581c371da6e3
  Result:         pass
  Rule:           validate-registries
  Scored:         true
  Source:         kyverno
  Timestamp:
    Nanos:    0
    Seconds:  1705539793
Summary:
  Error:  0
  Fail:   1
  Pass:   1
  Skip:   0
  Warn:   0
Events:   <none>
```

The above output display the `nginx` Pod policy validation receiving a `fail` Result and validation error Message. In the other hand the `nginx-ecr` policy validation received a `pass` Result. Monitoring reports in this way could be an overhead for administrators. Kyverno also supports a GUI based tool for [Policy reporter](https://kyverno.github.io/policy-reporter/core/targets/#policy-reporter-ui). This is outside of this workshop's scope.

This Lab, you learned how to augment the Kubernetes PSA/PSS configurations with Kyverno. Pod Security Standards (PSS) and the in-tree Kubernetes implementation of these standards, Pod Security Admission (PSA), provide good building blocks for managing pod security. The majority of users switching from Kubernetes Pod Security Policies (PSP) should be successful using the PSA/PSS features.

Kyverno augments the user experience created by PSA/PSS by leveraging the in-tree Kubernetes pod security implementation and providing several helpful enhancements. You can use Kyverno to govern the proper use of pod security labels. In addition, you can use the new Kyverno `validate.podSecurity` rule to easily manage pod security standards with additional flexibility and an enhanced user experience. And, with the Kyverno CLI, you can automate policy evaluation, upstream of your clusters.
