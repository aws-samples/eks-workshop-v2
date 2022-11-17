---
title: "Consume Additional Prefixes"
sidebar_position: 40
---

To demonstrate VPC CNI  behavior of adding additional prefixes to our worker nodes, we will deploy pause pods to utilize more IP addresses than are currently assigned. We are utilizing a large number of these pods to simulate the addition of application pods in to the cluster either through deployments or scaling operations. This will spin up `150 pods` and may take some time.

```bash
$ kubectl apply -k /workspace/modules/networking/prefix
$ kubectl wait --for=condition=available --timeout=60s deployment/pause-pods-prefix -n other
```

Check the pause pods are in a running state.

```bash test=false
$ kubectl get pods -l run=pause-pods-prefix -n other
```

Once the pods are running successfully, we should be able to see the additional prefixes added to the worker nodes.

```bash
$ aws ec2 describe-instances --filters "Name=tag-key,Values=eks:cluster-name" "Name=tag-value,Values=${EKS_CLUSTER_NAME}" \
  --query 'Reservations[*].Instances[].{InstanceId: InstanceId, Prefixes: NetworkInterfaces[].Ipv4Prefixes[]}'
```
