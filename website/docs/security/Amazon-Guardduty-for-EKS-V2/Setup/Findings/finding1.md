---
title: "Execution:Kubernetes/ExecInKubeSystemPod"
sidebar_position: 124
---



The anonymous user system:anonymous was granted API permissions on the EKS cluster cluster-2. This enables unauthenticated access to the permitted APIs.

Run the below commands to generate this finding. Note, the exact pod name varies in the second command. Use the pod name you see for the kube-proxy pod as displayed in the output of the first command.

```bash
$ KUBE_PROXY_POD=`kubectl get pods -n kube-system -l k8s-app=kube-proxy -o name | head -n 1`
$ kubectl -n kube-system exec $KUBE_PROXY_POD -- pwd
/
```

Go back to the GuardDuty console to check if a finding is generated.

![](exec_finding.png)
