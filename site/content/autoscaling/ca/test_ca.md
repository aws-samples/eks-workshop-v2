---
title: "Scale a Cluster with CA"
weight: 40
---

## Deploy a Sample App

We will deploy an sample nginx application as a `ReplicaSet` of 1 `Pod`

```bash
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-to-scaleout
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        service: nginx
        app: nginx
    spec:
      containers:
      - image: nginx
        name: nginx-to-scaleout
        resources:
          limits:
            cpu: 500m
            memory: 512Mi
          requests:
            cpu: 500m
            memory: 512Mi
EOF

kubectl wait --for=condition=available --timeout=60s deployment/nginx-to-scaleout
```

## Scale our ReplicaSet

Let's scale out the replicaset to 10

```bash hook=ca-pod-scaleout
kubectl scale --replicas=10 deployment/nginx-to-scaleout
```

Some pods will be in the `Pending` state, which triggers the cluster-autoscaler to scale out the EC2 fleet.

```bash test=false
kubectl get pods -l app=nginx -o wide --watch
```

{{< output >}}
NAME                                 READY   STATUS    RESTARTS   AGE   IP            NODE                          NOMINATED NODE   READINESS GATES
nginx-to-scaleout-6fcd49fb84-7j28k   1/1     Running   0          15s   10.42.10.27   ip-10-42-10-28.ec2.internal   <none>           <none>
nginx-to-scaleout-6fcd49fb84-9ksv6   0/1     Pending   0          7s    <none>        <none>                        <none>           <none>
nginx-to-scaleout-6fcd49fb84-c5sps   1/1     Running   0          7s    10.42.10.79   ip-10-42-10-28.ec2.internal   <none>           <none>
nginx-to-scaleout-6fcd49fb84-cp78b   0/1     Pending   0          7s    <none>        <none>                        <none>           <none>
nginx-to-scaleout-6fcd49fb84-gj4pq   0/1     Pending   0          7s    <none>        <none>                        <none>           <none>
nginx-to-scaleout-6fcd49fb84-lmm7q   0/1     Pending   0          7s    <none>        <none>                        <none>           <none>
nginx-to-scaleout-6fcd49fb84-lpzsk   0/1     Pending   0          7s    <none>        <none>                        <none>           <none>
nginx-to-scaleout-6fcd49fb84-psr6v   0/1     Pending   0          7s    <none>        <none>                        <none>           <none>
nginx-to-scaleout-6fcd49fb84-zcjdx   0/1     Pending   0          7s    <none>        <none>                        <none>           <none>
nginx-to-scaleout-6fcd49fb84-zpls2   0/1     Pending   0          7s    <none>        <none>                        <none>           <none>
{{< /output >}}

View the cluster-autoscaler logs

```bash test=false
kubectl -n kube-system logs -f deployment/cluster-autoscaler-aws-cluster-autoscaler
```

You will notice Cluster Autoscaler events similar to below
![CA Scale Up events](/images/scaling-asg-up2.png)

Check the [EC2 AWS Management Console](https://console.aws.amazon.com/ec2/home?#Instances:sort=instanceId) to confirm that the Auto Scaling groups are scaling up to meet demand. This may take a few minutes. You can also follow along with the pod deployment from the command line. You should see the pods transition from pending to running as nodes are scaled up.

![Scale Up](/images/scaling-asg-up.png)

or by using the kubectl

```bash
kubectl get nodes
```

Output

{{< output >}}
NAME                           STATUS   ROLES    AGE     VERSION
ip-10-42-10-28.ec2.internal    Ready    <none>   10m     v1.22.9-eks-810597c
ip-10-42-11-67.ec2.internal    Ready    <none>   2m24s   v1.22.9-eks-810597c
ip-10-42-12-158.ec2.internal   Ready    <none>   2m24s   v1.22.9-eks-810597c
{{< /output >}}
