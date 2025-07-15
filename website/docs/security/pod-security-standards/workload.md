---
title: "Test workload"
sidebar_position: 10
---

To test the various features of PSS let's start by deploying a workload to our EKS cluster that we can use. We'll use a simple Nginx deployment:

::yaml{file="manifests/modules/security/pss-psa/workload/deployment.yaml"}

Apply this to our cluster:

```bash
$ kubectl apply -k ~/environment/eks-workshop/modules/security/pss-psa/workload
namespace/nginx created
deployment.apps/nginx created
$ kubectl wait --for=condition=Ready pod -n nginx --timeout=60s
```
