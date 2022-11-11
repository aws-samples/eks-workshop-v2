---
title: "Cleanup"
sidebar_position: 80
weight: 80
---

### Uninstall the RPM package

```bash
$ sudo yum remove -y $(sudo yum list installed | grep amzn2extra-postgresql12 | awk '{ print $1}')
```

### Delete kubernetes element

```bash
$ kubectl -n sg-per-pod delete -f https://www.eksworkshop.com/beginner/115_sg-per-pod/deployments.files/green-pod.yaml

$ kubectl -n sg-per-pod delete -f https://www.eksworkshop.com/beginner/115_sg-per-pod/deployments.files/red-pod.yaml

$ kubectl -n sg-per-pod delete -f ~/environment/sg-per-pod/sg-policy.yaml

$ kubectl -n sg-per-pod delete secret rds
```

### Delete the namespace

```bash
$ kubectl delete ns sg-per-pod
```

### Disable ENI trunking

```bash
$ kubectl -n kube-system set env daemonset aws-node ENABLE_POD_ENI=false

$ kubectl -n kube-system rollout status ds aws-node
```

### Detach the IAM policy

```bash
$ aws iam detach-role-policy \
    --policy-arn arn:aws:iam::aws:policy/AmazonEKSVPCResourceController \
    --role-name ${ROLE_NAME}
```

### Delete POD Security Group

```bash
$ aws ec2 delete-security-group \
    --group-id ${POD_SG}
```

### Remove the trunk label

```bash
$ kubectl label node  --all 'vpc.amazonaws.com/has-trunk-attached'-
```

### Delete files

```bash
$ cd ~/environment

$ rm -rf sg-per-pod
```
