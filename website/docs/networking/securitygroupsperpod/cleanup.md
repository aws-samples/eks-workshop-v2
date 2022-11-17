---
title: "Cleanup"
sidebar_position: 80
weight: 80
---

Delete the sample applications:

```bash
$ kubectl delete ns sg-per-pod
```

Remove the security group rules

```bash
$ aws ec2 revoke-security-group-ingress \
--group-id ${NETWORKING_RDS_SG_ID} \
--protocol tcp \
--port 5432 \
--source-group ${POD_SG}

$ aws ec2 revoke-security-group-ingress \
--group-id ${CLUSTER_SG} \
--protocol tcp \
--port 53 \
--source-group ${POD_SG}

$ aws ec2 revoke-security-group-ingress \
--group-id ${CLUSTER_SG} \
--protocol udp \
--port 53 \
--source-group ${POD_SG}

$ aws ec2 revoke-security-group-ingress \
--group-id ${NETWORKING_RDS_SG_ID} \
--protocol tcp \
--port 5432 \
--source-group ${C9_SG}
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
