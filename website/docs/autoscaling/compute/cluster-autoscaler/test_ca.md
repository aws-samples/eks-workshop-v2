---
title: "Scale with CA"
sidebar_position: 40
---

We're going to update the `orders` service to consume more resources by increasing its memory request manually scaling it out horizontally. This will trigger the creation of more Pods, some of which will be unschedulable due to lack of resources in the existing compute instances.

```kustomization
autoscaling/compute/cluster-autoscaler/deployment.yaml
Deployment/orders
```

Let's apply this to our cluster:

```bash hook=ca-pod-scaleout timeout=180
$ kubectl apply -k /workspace/modules/autoscaling/compute/cluster-autoscaler
```

Some pods will be in the `Pending` state, which triggers the cluster-autoscaler to scale out the EC2 fleet.

```bash test=false
$ kubectl get pods -l app=nginx -o wide --watch
```

View the cluster-autoscaler logs

```bash test=false
$ kubectl -n kube-system logs \
  -f deployment/cluster-autoscaler-aws-cluster-autoscaler
```

Check the [EC2 AWS Management Console](https://console.aws.amazon.com/ec2/home?#Instances:sort=instanceId) to confirm that the Auto Scaling groups are scaling up to meet demand. This may take a few minutes. You can also follow along with the pod deployment from the command line. You should see the pods transition from pending to running as nodes are scaled up.

Alternatively you can use `kubectl`:

```bash
$ kubectl get nodes -l workshop-default=yes
NAME                           STATUS   ROLES    AGE     VERSION
ip-10-42-10-28.ec2.internal    Ready    <none>   10m     v1.22.9-eks-810597c
ip-10-42-11-67.ec2.internal    Ready    <none>   2m24s   v1.22.9-eks-810597c
ip-10-42-12-158.ec2.internal   Ready    <none>   2m24s   v1.22.9-eks-810597c
```
