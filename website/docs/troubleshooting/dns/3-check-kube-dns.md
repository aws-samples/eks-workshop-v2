---
title: "Checking kube-dns service"
sidebar_position: 53
---

In Kubernetes, pods use their configured nameservers for DNS resolution. The nameserver configuration is stored in `/etc/resolv.conf`, and by default, Kubernetes configures the kube-dns service ClusterIP as the nameserver for all pods.

### Step 1 - Check pod's resolv.conf

Let's verify this configuration by checking the nameserver setting in a pod:

```bash timeout=30
$ kubectl exec -it -n catalog catalog-mysql-0 -- cat /etc/resolv.conf
search catalog.svc.cluster.local svc.cluster.local cluster.local us-west-2.compute.internal
nameserver 172.20.0.10
options ndots:5
```

### Step 2 - Check kube-dns service IP

Now, let's confirm this IP matches the kube-dns service ClusterIP:

```bash timeout=30
$ kubectl get svc kube-dns -n kube-system
NAME       TYPE        CLUSTER-IP    EXTERNAL-IP   PORT(S)                  AGE
kube-dns   ClusterIP   172.20.0.10   <none>        53/UDP,53/TCP,9153/TCP   22d
```

The nameserver IP matches the kube-dns service ClusterIP, which is correct.

### Step 3 - Check kube-dns service endpoints

Next, verify that the kube-dns service is properly configured to route traffic to CoreDNS pods:

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

Compare these endpoints with CoreDNS pod IPs:

```bash timeout=30
$ kubectl get pod -l k8s-app=kube-dns -n kube-system -o wide
NAME                       READY   STATUS    RESTARTS   AGE   IP             ...
CoreDNS-787cb67946-72sqg   1/1     Running   0          18h   10.42.122.16   ...
CoreDNS-787cb67946-gtddh   1/1     Running   0          22d   10.42.153.96   ...
```

The service endpoints match the CoreDNS pod IPs, confirming proper service configuration.

:::note
Your environment will show different IPs. What matters is that the service endpoints match the CoreDNS pod IPs.
:::

### Step 4 - Check kube-proxy pods

Let's verify kube-proxy functionality.

Kube-proxy manages service routing within the cluster. It's responsible for routing DNS traffic from the kube-dns service to CoreDNS pods.

Check kube-proxy pod status:

```bash timeout=30
$ kubectl get pod -n kube-system -l k8s-app=kube-proxy
NAME               READY   STATUS             RESTARTS      AGE
kube-proxy-b4kk4   0/1     CrashLoopBackOff   2 (20s ago)   35s
kube-proxy-hqw8v   0/1     CrashLoopBackOff   2 (21s ago)   34s
kube-proxy-rqszf   0/1     CrashLoopBackOff   2 (21s ago)   35s
```

We've discovered another issue: kube-proxy pods are failing!

Examine kube-proxy logs:

```bash timeout=30
$ kubectl logs -n kube-system -l k8s-app=kube-proxy
...
E1109 22:18:36.012740       1 proxier.go:634] "Could not create dummy VS" err="no such file or directory" scheduler="r"
E1109 22:18:36.012763       1 server.go:558] "Error running ProxyServer" err="can't use the IPVS proxier: no such file or directory"
E1109 22:18:36.012808       1 run.go:74] "command failed" err="can't use the IPVS proxier: no such file or directory"
```

The logs indicate an IPVS configuration issue.

:::info
IPVS (IP Virtual Server) is an alternative kube-proxy mode that uses hash tables for packet processing, offering better performance in large clusters.
:::

### Root Cause

A misconfiguration of kube-proxy's IPVS mode is causing pod failures. When kube-proxy fails, it cannot set up ClusterIP rules for services, including kube-dns, which disrupts DNS resolution cluster-wide.

### Resolution

To fix this issue, we will rollback kube-proxy configuration to its default mode: **iptables**.

For more information about IPVS mode, see [Running kube-proxy in IPVS Mode](https://docs.aws.amazon.com/eks/latest/best-practices/ipvs.html).

Use AWS CLI to apply the default kube-proxy addon configuration. Note that passing an empty configuration applies the default kube-proxy iptables mode:

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

Redeploy kube-proxy pods and wait for the update to complete:

```bash timeout=180 wait=5
$ kubectl -n kube-system delete pod -l "k8s-app=kube-proxy"
$ aws eks wait addon-active --cluster-name $EKS_CLUSTER_NAME --region $AWS_REGION  --addon-name kube-proxy
```

Verify kube-proxy pods are running:

```bash timeout=30
$ kubectl get pod -n kube-system -l k8s-app=kube-proxy
NAME               READY   STATUS    RESTARTS   AGE
kube-proxy-8c4t9   1/1     Running   0          3m13s
kube-proxy-fkr7m   1/1     Running   0          3m13s
kube-proxy-nttzw   1/1     Running   0          3m13s
```

Check kube-proxy logs for any errors:

```bash timeout=30
$ kubectl logs -n kube-system -l k8s-app=kube-proxy
...
I1109 22:33:34.994403       1 proxier.go:799] "SyncProxyRules complete" elapsed="63.815782ms"
I1109 22:33:34.994427       1 proxier.go:805] "Syncing iptables rules"
I1109 22:33:35.035283       1 proxier.go:1494] "Reloading service iptables data" numServices=0 numEndpoints=0 numFilterChains=5 numFilterRules=3 numNATChains=4 numNATRules=5
I1109 22:33:35.099387       1 proxier.go:799] "SyncProxyRules complete" elapsed="104.958328ms"
```

### Next Steps

We've resolved the kube-proxy configuration issue, ensuring proper communication between application pods and CoreDNS through the kube-dns service.

Let's proceed to the final troubleshooting steps in the next lab.
