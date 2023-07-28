---
title: "Unsafe execution into pod in `kube-system` namespace"
sidebar_position: 124
---

This finding indicates that a command was executed inside a pod in kube-system namespace on EKS Cluster.

Run the below commands to generate this finding. 

```bash
$ kubectl -n kube-system exec $(kubectl -n kube-system get pods -o name -l k8s-app=kube-proxy| head -n1) -c kube-proxy -- pwd
/
```

Within a few minutes we'll see the finding `Execution:Kubernetes/ExecInKubeSystemPod` in the GuardDuty portal.

![](exec_finding.png)
