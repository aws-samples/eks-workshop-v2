---
title: "Reports & Auditing"
sidebar_position: 74
---

Kyverno includes a [Policy Reporting](https://kyverno.io/docs/policy-reports/) tool that uses an open format defined by the Kubernetes Policy Working Group. These reports are deployed as custom resources in the cluster. Kyverno generates these reports when admission actions like _CREATE_, _UPDATE_, and _DELETE_ are performed in the cluster. Reports are also generated as a result of background scans that validate policies on existing resources.

Throughout this workshop, we have created several policies with specific rules. When a resource matches one or more rules according to the policy definition and violates any of them, an entry is created in the report for each violation. This can result in multiple entries if the same resource matches and violates multiple rules. When resources are deleted, their entries are removed from the reports. This means that Kyverno Reports always represent the current state of the cluster and do not record historical information.

As discussed earlier, Kyverno has two types of `validationFailureAction`:

1. `Audit` mode: Allows resources to be created and reports the action in the Policy Reports.
2. `Enforce` mode: Denies resource creation but does not add an entry in the Policy Reports.

For example, if a Policy in `Audit` mode contains a single rule requiring all Deployments to set the label `CostCenter` on their pod template, and a Deployment is created without that label, Kyverno will allow the Deployment's creation but record it as a `FAIL` result in a Policy Report due to the rule violation. If this same Policy is configured with `Enforce` mode, Kyverno will immediately block the Deployment creation, and this will not generate an entry in the Policy Reports. However, if the Deployment is created in compliance with the rule, it will be reported as `PASS` in the report. You can check blocked actions in the Kubernetes events for the Namespace where the action was requested.

Let's examine our cluster's compliance status with the policies we've created so far in this workshop by reviewing the Policy Reports generated.

```bash hook=reports
$ kubectl get policyreports -A
NAMESPACE     NAME                                   KIND         NAME                            PASS   FAIL   WARN   ERROR   SKIP   AGE
carts         50358693-2468-4b73-8873-c6239b90876c   Deployment   carts-dynamodb                  1      2      0      0       0      23m
carts         b0356ab5-e6a5-4326-a931-0e8d1a9f7f94   Deployment   carts                           3      0      0      0       1      23m
catalog       d6c40501-8f34-4398-97a6-27ab1050ef93   Deployment   catalog                         2      1      0      0       0      23m
checkout      3f896219-057e-40c0-bf99-c6ad4a57350b   Deployment   checkout                        2      1      0      0       0      23m
checkout      4df6b9d4-b87f-4a83-bbc3-985227280d2a   Deployment   checkout-redis                  2      1      0      0       0      23m
default       b71aba03-a65c-4ee2-baa1-0fc35b3a68ab   Deployment   nginx-public                    3      1      0      0       0      94s
default       f9802e1a-d2ee-4ee6-a9e2-c6d6f9fc7dab   Deployment   nginx-ecr                       4      0      0      0       0      14s
kube-system   ad06d729-02ec-4423-a534-fed4f1291516   Deployment   metrics-server                  1      2      0      0       0      23m
kube-system   de7f93d3-b4e5-42db-99c0-21b41559f9e3   Deployment   coredns                         1      2      0      0       0      23m
kyverno       1cfa691f-f809-4d5e-95d1-0a2367a834b0   Deployment   kyverno-reports-controller      1      2      0      0       0      23m
kyverno       94f688ff-b3de-400d-b7b5-6a17ccfe0dbd   Deployment   kyverno-admission-controller    1      2      0      0       0      23m
kyverno       adbaf20a-359b-4828-9a38-b0a30bd54d84   Deployment   kyverno-cleanup-controller      1      2      0      0       0      23m
kyverno       dd887a98-1d6f-48f6-a114-ab49eccdaa38   Deployment   kyverno-background-controller   1      2      0      0       0      23m
orders        40ed7842-7592-48b3-8998-eff2b16a898f   Deployment   orders                          2      1      0      0       0      23m
ui            590ae540-0bcc-4caa-8154-f7907fb31ff1   Deployment   ui                              3      0      0      0       0      23m
```

> Note: The output may vary. Reports will be generated for Deployments across all Namespaces.

In Kyverno 1.13+, policy reports are scoped per-resource rather than per-policy. Each report is named by the resource's UID and shows the aggregated pass/fail counts across all policies that evaluated that resource. Because our policies target Deployments, the reports are scoped to Deployment resources. You can see that the reports show the status the resource using `PASS`, `FAIL`, `WARN`, `ERROR`, and `SKIP`.

As mentioned earlier, blocked actions are recorded in the Namespace events. Let's examine those using the following command:

```bash
$ kubectl get events | grep block
9m11s       Warning   PolicyViolation     clusterpolicy/baseline-policy             Deployment default/privileged-deploy: [baseline] fail (blocked); Validation rule 'baseline' failed. It violates PodSecurity "baseline:latest": (Forbidden reason: privileged, field error list: [spec.template.spec.containers[0].securityContext.privileged is forbidden, forbidden values found: true])
18m         Warning   PolicyViolation     clusterpolicy/require-labels              Deployment ui/ui: [check-team] fail (blocked); validation error: Label 'CostCenter' is required on the Deployment pod template. rule check-team failed at path /spec/template/metadata/labels/CostCenter/
2m8s        Warning   PolicyViolation     clusterpolicy/restrict-image-registries   Deployment default/nginx-blocked: [validate-registries] fail (blocked); validation error: Unknown Image registry. rule validate-registries failed at path /spec/template/spec/containers/0/image/
```

> Note: The output may vary.

Each event corresponds to a policy violation from earlier in this lab:
- `baseline-policy` blocked the `privileged-deploy` Deployment when we patched it to add `privileged: true`
- `require-labels` blocked the `ui` Deployment rollout restart because its pod template was missing the `CostCenter` label
- `restrict-image-registries` blocked `nginx-blocked` because its image came from an untrusted registry

These events give you a real-time audit trail of enforcement actions across the cluster.

Now, let's take a closer look at the Policy Reports for the `default` Namespace used in the labs:

```bash
$ kubectl get policyreports
NAME                                   KIND         NAME           PASS   FAIL   WARN   ERROR   SKIP   AGE
b71aba03-a65c-4ee2-baa1-0fc35b3a68ab   Deployment   nginx-public   3      1      0      0       0      3m39s
f9802e1a-d2ee-4ee6-a9e2-c6d6f9fc7dab   Deployment   nginx-ecr      4      0      0      0       0      2m19s
```

Notice that the `nginx-public` Deployment has 1 `FAIL` and the `nginx-ecr` Deployment has all passes. This is because all the ClusterPolicies were created with `Enforce` mode. Blocked resources are not reported, only resources that were admitted and then evaluated by the background scanner. The `nginx-public` Deployment, which we left running with a publicly available image, is the only remaining resource that violates the `restrict-image-registries` policy.

To examine the violations for the `nginx-public` Deployment in more detail, describe its report. Since reports are named by UID, use `kubectl get policyreports` to find the report name for the `nginx-public` Deployment, then describe it:

```bash
$ kubectl describe policyreport $(kubectl get policyreports -o json | jq -r '.items[] | select(.scope.name=="nginx-public") | .metadata.name')
Name:         a9b8c7d6-e5f4-3210-fedc-ba9876543210
Namespace:    default
Labels:       app.kubernetes.io/managed-by=kyverno
Annotations:  <none>
API Version:  wgpolicyk8s.io/v1alpha2
Kind:         PolicyReport
Scope:
  API Version:  apps/v1
  Kind:         Deployment
  Name:         nginx-public
  Namespace:    default
Results:
  Message:  validation error: Unknown Image registry. rule validate-registries failed at path /spec/template/spec/containers/0/image/
  Policy:   restrict-image-registries
  Result:   fail
  Rule:     validate-registries
  Scored:   true
  Source:   kyverno
  ...
Summary:
  Error:  0
  Fail:   1
  Pass:   3
  Skip:   0
  Warn:   0
Events:   <none>
```

The report shows the `nginx-public` Deployment's `fail` result for `restrict-image-registries` with the validation error message. The `nginx-ecr` Deployment has its own separate report with all passes. Monitoring reports in this way could be an overhead for administrators. Kyverno also supports a GUI-based tool for [Policy reporter](https://kyverno.github.io/policy-reporter/core/targets/#policy-reporter-ui), which is outside the scope of this workshop.

In this lab, you learned how to augment the Kubernetes PSA/PSS configurations with Kyverno. Pod Security Standards (PSS) and the in-tree Kubernetes implementation of these standards, Pod Security Admission (PSA), provide good building blocks for managing pod security. The majority of users switching from Kubernetes Pod Security Policies (PSP) should be successful using the PSA/PSS features.

Kyverno enhances the user experience created by PSA/PSS by leveraging the in-tree Kubernetes pod security implementation and providing several helpful enhancements. You can use Kyverno to govern the proper use of pod security labels. Additionally, you can use the new Kyverno `validate.podSecurity` rule to easily manage pod security standards with additional flexibility and an enhanced user experience. And, with the Kyverno CLI, you can automate policy evaluation upstream of your clusters.
