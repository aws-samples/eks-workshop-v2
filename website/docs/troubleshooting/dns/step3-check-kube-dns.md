---
title: "Checking kube-dns service"
sidebar_position: 53
---

Pods use their configured nameserver to resolve DNS names. In Linux systems, nameserver configuration is written to file `/etc/resolv.conf`. By default, Kubernetes writes the kube-dns service ClusterIP as nameserver on every pod, inside file `/etc/resolv.conf`.

Let’s check pod nameserver configuration to ensure that kube-dns service ClusterIP is set as nameserver in file `/etc/resolv.conf`. You can check any application pod becasue this configuration is globally applied to all pods in the cluster.

```bash timeout=30
$ kubectl exec -it -n catalog catalog-mysql-0 -- cat /etc/resolv.conf
search catalog.svc.cluster.local svc.cluster.local cluster.local us-west-2.compute.internal
nameserver 172.20.0.10
options ndots:5
```

The nameserver is set to IP 172.20.0.10.

Confirm that this is the kube-dns service ClusterIP:

```bash timeout=30
$ kubectl get svc kube-dns -n kube-system
NAME       TYPE        CLUSTER-IP    EXTERNAL-IP   PORT(S)                  AGE
kube-dns   ClusterIP   172.20.0.10   <none>        53/UDP,53/TCP,9153/TCP   22d
```

Perfect!
The nameserver in file `/etc/resolv.conf` is pointing to kube-dns ClusterIP.

Now, let’s ensure that kube-dns service points to Coredns pods.
For that, check the endpoints for service kube-dns:

```bash timeout=30
$ kubectl describe svc kube-dns -n kube-system
...
IP:                172.20.0.10
IPs:               172.20.0.10
Port:              dns  53/UDP
TargetPort:        53/UDP
Endpoints:         10.42.122.16:53,10.42.153.96:53
Port:              dns-tcp  53/TCP
TargetPort:        53/TCP
Endpoints:         10.42.122.16:53,10.42.153.96:53
...
```

Then, ensure that kube-dns service endpoints are set to Coredns pod IP addresses:

```bash timeout=30
$ kubectl get pod -l k8s-app=kube-dns -n kube-system -o wide
NAME                       READY   STATUS    RESTARTS   AGE   IP             ...
coredns-787cb67946-72sqg   1/1     Running   0          18h   10.42.122.16   ...
coredns-787cb67946-gtddh   1/1     Running   0          22d   10.42.153.96   ...
```

Excellent, we can see that kube-dns service endpoints align with Coredns pod IP addresses.

In your environment, coredns IPs will be different than the IPs in this output. The requirement is that the IPs shown in the service Endpoints section are the same as the IPs shown for coredns pods.

Last, we need to verify that kube-proxy is working without issues.

:::info
Kube-proxy is responsible for configuring service routing inside the cluster. When DNS resolution traffic goes to kube-dns service, kube-proxy configuration is used to routed this traffic to Coredns pods.
:::

First, check that kube-proxy pods are up and running:

```bash timeout=30
$ kubectl get pod -n kube-system -l k8s-app=kube-proxy
NAME               READY   STATUS             RESTARTS      AGE
kube-proxy-b4kk4   0/1     CrashLoopBackOff   2 (20s ago)   35s
kube-proxy-hqw8v   0/1     CrashLoopBackOff   2 (21s ago)   34s
kube-proxy-rqszf   0/1     CrashLoopBackOff   2 (21s ago)   35s
```

We found another problem: kube-proxy pods are not running!

Check kube-proxy logs to know what is happening when it tries to run:

```bash timeout=30
$ kubectl logs -n kube-system -l k8s-app=kube-proxy
...
E1109 22:18:36.012740       1 proxier.go:634] "Could not create dummy VS" err="no such file or directory" scheduler="r"
E1109 22:18:36.012763       1 server.go:558] "Error running ProxyServer" err="can't use the IPVS proxier: no such file or directory"
E1109 22:18:36.012808       1 run.go:74] "command failed" err="can't use the IPVS proxier: no such file or directory"
```

The last line of the logs shows that kube-proxy fails due to an issue related to IPVS configuration.

:::info
IPVS is a configuration mode for kube-proxy that uses hash tables rather than linear searching to process packets, providing efficiency for clusters with thousands of nodes and services.
:::

### Root Cause

While trying to update the configuration mode for kube-proxy, users may apply a bad configuration and cause kube-proxy to fail. Then, kube-proxy is not able to set up ClusterIP rules for Kubernetes services, including kube-dns service. Connections to kube-dns service fail and DNS resolution in the cluster is impaired.

### How to resolve this issue?

To fix this issue, we will rollback kube-proxy configuration to its default mode: **iptables**.

If you would like to read further about kube-proxy IPVS mode and how to configure it, check out [Running kube-proxy in IPVS Mode](https://docs.aws.amazon.com/eks/latest/best-practices/ipvs.html).

Use aws cli to apply the default kube-proxy addon configuration. Note that we are passing an empty configuration in this update command, which applies the default kube-proxy iptables mode:

```bash timeout=30 wait=5
$ aws eks update-addon --cluster-name $EKS_CLUSTER_NAME --addon-name kube-proxy --region $AWS_REGION \
  --configuration-values '{}' \
  --resolve-conflicts OVERWRITE
  {
    "update": {
        "id": "466640b1-b233-38a4-8358-e7e90519adee",
        "status": "InProgress",
        "type": "AddonUpdate",
        "params": [
            {
                "type": "ResolveConflicts",
                "value": "OVERWRITE"
            },
            {
                "type": "ConfigurationValues",
                "value": "{}"
            }
        ],
        "createdAt": "2024-11-09T22:31:36.383000+00:00",
        "errors": []
    }
}
```

Then, re-deploy kube-proxy pods and wait for the addon update to complete:

```bash timeout=180 wait=5
$ kubectl -n kube-system delete pod -l "k8s-app=kube-proxy"
$ aws eks wait addon-active --cluster-name $EKS_CLUSTER_NAME --region $AWS_REGION  --addon-name kube-proxy
```

Now, check kube-proxy pods to ensure that they are Ready:

```bash timeout=30
$ kubectl get pod -n kube-system -l k8s-app=kube-proxy
NAME               READY   STATUS    RESTARTS   AGE
kube-proxy-8c4t9   1/1     Running   0          3m13s
kube-proxy-fkr7m   1/1     Running   0          3m13s
kube-proxy-nttzw   1/1     Running   0          3m13s
```

Also, check kube-proxy logs to make sure that there are no errors in the logs:

```bash timeout=30
$ kubectl logs -n kube-system -l k8s-app=kube-proxy
...
I1109 22:33:34.994403       1 proxier.go:799] "SyncProxyRules complete" elapsed="63.815782ms"
I1109 22:33:34.994427       1 proxier.go:805] "Syncing iptables rules"
I1109 22:33:35.035283       1 proxier.go:1494] "Reloading service iptables data" numServices=0 numEndpoints=0 numFilterChains=5 numFilterRules=3 numNATChains=4 numNATRules=5
I1109 22:33:35.099387       1 proxier.go:799] "SyncProxyRules complete" elapsed="104.958328ms"
```

### Next Steps

At this point, we have resolved the issue with kube-proxy configuration and kube-proxy pods are running as expected now. This enures that our application pods can communicate with kubedns service and perform DNS resolution with coredns pods.

Let's continue to the next lab to cover the last troubleshooting steps that will cover in this lab.
