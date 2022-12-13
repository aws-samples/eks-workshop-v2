---
title: "Cleanup"
sidebar_position: 133
---

To clean up all created resources in Amazon GuardDuty for EKS section please run the following commands.

```bash
$ kubectl delete rolebinding pod-access -n default
$ kubectl delete role pod-create -n default
$ kubectl delete clusterrolebinding anonymous-view
$ kubectl delete pod nginx -n default
$ kubectl delete rolebinding pod-access psp-access -n default
$ kubectl delete role pod-create psp-use -n default
$ kubectl delete rolebinding sa-default-admin --namespace=default
$ kubectl delete -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.5.1/aio/deploy/recommended.yaml
$ kubectl delete -f /workspace/modules/security/Guardduty/privileged/mount/privileged-pod-example.yaml
```

Finally disable GuardDuty:

```bash
$ DetectorIds=`aws guardduty list-detectors --output text --query DetectorIds`
$ aws guardduty delete-detector  --detector-id  $DetectorIds
```
