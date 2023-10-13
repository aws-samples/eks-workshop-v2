---
title: "Summary"
sidebar_position: 139
---

## Cleaning Up:

To remove Kyverno from your cluster, you can follow the uninstall instructions. The helm uninstall command is seen below:

```
helm uninstall kyverno kyverno/kyverno --namespace kyverno
```

As mentioned in the Kyverno documentation, Kyverno will try to remove all its webhook configurations. This can be done manually or as a final step with the following kubectl command:

```
kubectl delete mutatingwebhookconfigurations kyverno-policy-mutating-webhook-cfg kyverno-resource-mutating-webhook-cfg kyverno-verify-mutating-webhook-cfg
kubectl delete validatingwebhookconfigurations kyverno-policy-validating-webhook-cfg kyverno-resource-validating-webhook-cfg
```

In this Workshop, we showed you how to augment the Kubernetes PSA/PSS configurations with Kyverno. Pod Security Standards (PSS) and the in-tree Kubernetes implementation of these standards, Pod Security Admission (PSA), provide good building blocks for managing pod security. The majority of users switching from Kubernetes Pod Security Policies (PSP) should be successful using the PSA/PSS features.

Kyverno augments the user experience created by PSA/PSS, by leveraging the in-tree Kubernetes pod security implementation, and providing several helpful enhancements for operationalization. You can use Kyverno to govern the proper use of pod security labels. In addition, you can use the new Kyverno ```validate.podSecurity``` rule to easily manage pod security standards with additional flexibility and an enhanced user experience. And, with the Kyverno CLI, you can automate policy evaluation, upstream of your clusters.