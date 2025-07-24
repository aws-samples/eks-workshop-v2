---
title: "Test workload"
sidebar_position: 10
---

To test the various features of PSS let's start by deploying a workload to our EKS cluster that we can use. We'll create a separate deployment of the catalog component to experiment with in its own namespace:

::yaml{file="manifests/modules/security/pss-psa/workload/deployment.yaml"}

Apply this to our cluster:

```bash
$ kubectl apply -k ~/environment/eks-workshop/modules/security/pss-psa/workload
namespace/pss created
deployment.apps/pss created
$ kubectl rollout status -n pss deployment/pss --timeout=60s
```
