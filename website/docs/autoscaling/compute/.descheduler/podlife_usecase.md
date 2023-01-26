---
title: "Pod Lifetime use-case"
sidebar_position: 4
---

`PodLifeTime` strategy evicts pods that are older than `maxPodLifeTimeSeconds`. You can also specify podStatusPhases to only evict pods with specific StatusPhases, currently this parameter is limited to `Running` and `Pending`.

This strategy is useful to balance a cluster by Pod Age, when initially migrating applications from a static virtual machine infrastructure to a cloud native k8s infrastructure there can be a tendency to treat application pods like static virtual machines. One approach to help prevent developers and operators from treating pods like virtual machines is to ensure that pods only run for a fixed amount of time.

In our setup, Descheduler policy is configured to evict pods older than 120 seconds with `podlifetime=enabled` label.

```yaml
"PodLifeTime":
  enabled: true
  params:
    podLifeTime:
      maxPodLifeTimeSeconds: 120
    labelSelector:
      matchLabels:
        podlifetime: enabled
```

Let's start running by modifying the `checkout` service to add the label `podlifetime=enabled`:

KUSTOMIZE HERE

Watch the pod status by running the below command, notice the pods being evicted every time it runs for more than 120 seconds:

```bash test=false
$ kubectl get pods -l podlifetime=enabled --watch 
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
```

Press `Ctrl + C` to return to the command prompt. You can also look at the descheduler logs for more analysis

```bash test=false
$ kubectl logs -n kube-system deployment/descheduler
I0610 03:58:23.658264       1 descheduler.go:278] Building a pod evictor
I0610 03:58:23.658303       1 pod_lifetime.go:104] "Processing node" node="ip-10-14-10-225.us-west-2.compute.internal"
I0610 03:58:23.658392       1 pod_lifetime.go:104] "Processing node" node="ip-10-14-11-249.us-west-2.compute.internal"
I0610 03:58:23.675177       1 evictions.go:163] "Evicted pod" pod="default/nginx-lifetime-68db49fb68-4x6l5" reason="PodLifeTime" strategy="PodLifeTime" node="ip-10-14-11-249.us-west-2.compute.internal"
I0610 03:58:23.675245       1 pod_lifetime.go:110] "Evicted pod because it exceeded its lifetime" pod="default/nginx-lifetime-68db49fb68-4x6l5" maxPodLifeTime=120
I0610 03:58:23.675257       1 pod_lifetime.go:104] "Processing node" node="ip-10-14-12-91.us-west-2.compute.internal"
....
I0610 03:58:23.676115       1 descheduler.go:304] "Number of evicted pods" totalEvicted=1
I0610 03:58:23.676141       1 event.go:294] "Event occurred" object="default/nginx-lifetime-68db49fb68-4x6l5" fieldPath="" kind="Pod" apiVersion="v1" type="Normal" reason="Descheduled" message="pod evicted by sigs.k8s.io/deschedulerPodLifeTime"
```
