---
title: "Scale with CA"
sidebar_position: 40
---

In this lab exercise, we'll update all of the application components to increase their replica count to 4. This will cause more resources to be consumed than are available in a cluster, triggering more compute to be provisioned.

```file
autoscaling/compute/cluster-autoscaler/deployment.yaml
```

Let's apply this to our cluster:

```bash hook=ca-pod-scaleout timeout=180
$ kubectl apply -k /workspace/modules/autoscaling/compute/cluster-autoscaler
```

Some pods will be in the `Pending` state, which triggers the cluster-autoscaler to scale out the EC2 fleet.

```bash test=false
$ kubectl get pods -n orders -o wide --watch
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
NAME                                         STATUS   ROLES    AGE     VERSION
ip-10-42-10-159.us-west-2.compute.internal   Ready    <none>   3d      v1.23.9-eks-ba74326
ip-10-42-11-143.us-west-2.compute.internal   Ready    <none>   2m49s   v1.23.9-eks-ba74326
ip-10-42-11-81.us-west-2.compute.internal    Ready    <none>   3d      v1.23.9-eks-ba74326
ip-10-42-12-152.us-west-2.compute.internal   Ready    <none>   3m11s   v1.23.9-eks-ba74326
```
