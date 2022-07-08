---
title: "Pod Lifetime usecase"
date: 2022-06-09T00:00:00-03:00
weight: 4
---

### PodLifeTime

`PodLifeTime` strategy evicts pods that are older than `maxPodLifeTimeSeconds`. You can also specify podStatusPhases to only evict pods with specific StatusPhases, currently this parameter is limited to `Running` and `Pending`.

This strategy is useful to balance the cluster by Pod Age, when initially migrating applications from a static virtual machine infrastructure to a cloud native k8s infrastructure there can be a tendency to treat application pods like static virtual machines. One approach to help prevent developers and operators from treating pods like virtual machines is to ensure that pods only run for a fixed amount of time.

In our setup, Descheduler policy is configured to evict pods older than 120 seconds with `podlifetime=enabled` label.

{{< output >}}
"PodLifeTime":
  enabled: true
  params:
    podLifeTime:
      maxPodLifeTimeSeconds: 120
    labelSelector:
      matchLabels:
        podlifetime: enabled
{{< /output >}}

Lets start running a test pod with `podlifetime=enabled` label.

```bash
cat <<EoF > podlife-nginx.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-podlife
  labels:
    app: nginx-podlife
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nginx-podlife
  template:
    metadata:
      labels:
        app: nginx-podlife
        podlifetime: enabled
    spec:
      containers:
      - name: nginx
        image: nginx
        ports:
        - containerPort: 80
EoF

kubectl apply -f podlife-nginx.yaml
```
Output will look like:

{{< output >}}
deployment.apps/nginx-lifetime created
{{< /output >}}

Watch the pod status by running the below command, you will notice the pod being evicted every time the podlifetime is expired.

```bash test=false
kubectl get pods -l podlifetime=enabled --watch 
```

Output will look like:

{{< output >}}
NAME                              READY   STATUS              RESTARTS   AGE
nginx-lifetime-68db49fb68-4x6l5   1/1     Running             0          2m24s
nginx-lifetime-68db49fb68-4x6l5   1/1     Terminating         0          3m
nginx-lifetime-68db49fb68-zk56p   0/1     Pending             0          0s
nginx-lifetime-68db49fb68-zk56p   0/1     Pending             0          0s
nginx-lifetime-68db49fb68-zk56p   0/1     ContainerCreating   0          0s
nginx-lifetime-68db49fb68-4x6l5   0/1     Terminating         0          3m
nginx-lifetime-68db49fb68-4x6l5   0/1     Terminating         0          3m1s
nginx-lifetime-68db49fb68-4x6l5   0/1     Terminating         0          3m1s
nginx-lifetime-68db49fb68-zk56p   1/1     Running             0          2s
{{< /output >}}

Press `Ctrl + C` to return to the command prompt. You can also look at the descheduler logs for more analysis

```bash test=false
kubectl logs -n kube-system deployment/descheduler
```

{{< output >}}
I0610 03:58:23.658264       1 descheduler.go:278] Building a pod evictor
I0610 03:58:23.658303       1 pod_lifetime.go:104] "Processing node" node="ip-10-14-10-225.us-west-2.compute.internal"
I0610 03:58:23.658392       1 pod_lifetime.go:104] "Processing node" node="ip-10-14-11-249.us-west-2.compute.internal"
I0610 03:58:23.675177       1 evictions.go:163] "Evicted pod" pod="default/nginx-lifetime-68db49fb68-4x6l5" reason="PodLifeTime" strategy="PodLifeTime" node="ip-10-14-11-249.us-west-2.compute.internal"
I0610 03:58:23.675245       1 pod_lifetime.go:110] "Evicted pod because it exceeded its lifetime" pod="default/nginx-lifetime-68db49fb68-4x6l5" maxPodLifeTime=120
I0610 03:58:23.675257       1 pod_lifetime.go:104] "Processing node" node="ip-10-14-12-91.us-west-2.compute.internal"
....
I0610 03:58:23.676115       1 descheduler.go:304] "Number of evicted pods" totalEvicted=1
I0610 03:58:23.676141       1 event.go:294] "Event occurred" object="default/nginx-lifetime-68db49fb68-4x6l5" fieldPath="" kind="Pod" apiVersion="v1" type="Normal" reason="Descheduled" message="pod evicted by sigs.k8s.io/deschedulerPodLifeTime"
{{< /output >}}
