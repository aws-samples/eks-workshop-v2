---
title: "Cleanup"
sidebar_position: 80
weight: 80
---

Delete the sample applications:

```bash
$ kubectl delete ns sg-per-pod
```

Delete the pod security group:

```bash
$ aws ec2 delete-security-group \
    --group-id ${POD_SG}
```

Finally delete the files we created during the lab:

```bash
$ cd ~/environment

$ rm -rf sg-per-pod
```
