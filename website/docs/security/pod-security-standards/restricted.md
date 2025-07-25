---
title: "Restricted PSS Profile"
sidebar_position: 63
---

Finally we can take a look at the Restricted profile, which is the most heavily restricted policy following current Pod hardening best practices. Add labels to the `pss` namespace to enable all PSA modes for the Restricted PSS profile:

```kustomization
modules/security/pss-psa/restricted-namespace/namespace.yaml
Namespace/pss
```

Run Kustomize to apply this change to add labels to the `pss` namespace:

```bash
$ kubectl apply -k ~/environment/eks-workshop/modules/security/pss-psa/restricted-namespace
Warning: existing pods in namespace "pss" violate the new PodSecurity enforce level "restricted:latest"
Warning: pss-d59d88b99-flkgp: allowPrivilegeEscalation != false, runAsNonRoot != true, seccompProfile
namespace/pss configured
deployment.apps/pss unchanged
```

Similar to the Baseline profile we're getting a warning that the pss Deployment is violating the Restricted profile.

```bash
$ kubectl -n pss delete pod --all
pod "pss-d59d88b99-flkgp" deleted
```

The Pods aren't re-created:

```bash hook=no-pods
$ kubectl -n pss get pod
No resources found in pss namespace.
```

The above output indicates that PSA did not allow creation of Pods in the `pss` Namespace, because the Pod security configuration violates Restricted PSS profile. This behavior is same as what we saw earlier in the previous section.

In the case of the Restricted profile we actually need to proactively lock down some of the security configuration to meet the profile. Let's add some security controls to the Pod configuration to make it compliant with the Privileged PSS profile configured for the `pss` namespace:

```kustomization
modules/security/pss-psa/restricted-workload/deployment.yaml
Deployment/pss
```

Run Kustomize to apply these changes, which we re-create the Deployment:

```bash
$ kubectl apply -k ~/environment/eks-workshop/modules/security/pss-psa/restricted-workload
namespace/pss unchanged
deployment.apps/pss configured
$ kubectl rollout status -n pss deployment/pss --timeout=60s
```

Now, Run the below commands to check PSA allows the creation of Deployment and Pod with the above changes in the the `pss` namespace:

```bash
$ kubectl -n pss get pod
NAME                     READY   STATUS    RESTARTS   AGE
pss-8dd6fc8c6-9kptf      1/1     Running   0          3m6s
```

The above output indicates that PSA allowed since Pod security configuration confirms to the Restricted PSS profile.

Note that the above security permissions are not the comprehensive list of controls allowed under Restricted PSS profile. For detailed security controls allowed/disallowed under each PSS profile, refer to the [documentation](https://kubernetes.io/docs/concepts/security/pod-security-standards/#restricted).
