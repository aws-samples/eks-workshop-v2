---
title: "kube-dns 서비스 확인"
sidebar_position: 53
tmdTranslationSourceHash: 'ac41b853a5d83893ed638b730b903e72'
---

Kubernetes에서 Pod는 DNS 확인을 위해 구성된 네임서버를 사용합니다. 네임서버 구성은 `/etc/resolv.conf`에 저장되며, 기본적으로 Kubernetes는 모든 Pod의 네임서버로 kube-dns 서비스 ClusterIP를 구성합니다.

### 단계 1 - Pod의 resolv.conf 확인

Pod의 네임서버 설정을 확인하여 이 구성을 검증해 보겠습니다:

```bash timeout=30
$ kubectl exec -it -n catalog catalog-mysql-0 -- cat /etc/resolv.conf
search catalog.svc.cluster.local svc.cluster.local cluster.local us-west-2.compute.internal
nameserver 172.20.0.10
options ndots:5
```

### 단계 2 - kube-dns 서비스 IP 확인

이제 이 IP가 kube-dns 서비스 ClusterIP와 일치하는지 확인하겠습니다:

```bash timeout=30
$ kubectl get svc kube-dns -n kube-system
NAME       TYPE        CLUSTER-IP    EXTERNAL-IP   PORT(S)                  AGE
kube-dns   ClusterIP   172.20.0.10   <none>        53/UDP,53/TCP,9153/TCP   22d
```

네임서버 IP가 kube-dns 서비스 ClusterIP와 일치하며, 이는 올바른 구성입니다.

### 단계 3 - kube-dns 서비스 엔드포인트 확인

다음으로 kube-dns 서비스가 CoreDNS Pod로 트래픽을 라우팅하도록 올바르게 구성되어 있는지 확인합니다:

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

이 엔드포인트를 CoreDNS Pod IP와 비교합니다:

```bash timeout=30
$ kubectl get pod -l k8s-app=kube-dns -n kube-system -o wide
NAME                       READY   STATUS    RESTARTS   AGE   IP             ...
CoreDNS-787cb67946-72sqg   1/1     Running   0          18h   10.42.122.16   ...
CoreDNS-787cb67946-gtddh   1/1     Running   0          22d   10.42.153.96   ...
```

서비스 엔드포인트가 CoreDNS Pod IP와 일치하므로 서비스가 올바르게 구성되어 있음을 확인할 수 있습니다.

:::note
사용자 환경에서는 다른 IP가 표시됩니다. 중요한 것은 서비스 엔드포인트가 CoreDNS Pod IP와 일치하는지 여부입니다.
:::

### 단계 4 - kube-proxy Pod 확인

#### 4.1. kube-proxy 기능 확인

kube-proxy는 클러스터 내에서 서비스 라우팅을 관리합니다. kube-dns 서비스에서 CoreDNS Pod로 DNS 트래픽을 라우팅하는 역할을 담당합니다. kube-proxy Pod 상태를 확인해 보겠습니다:

```bash timeout=30
$ kubectl get pod -n kube-system -l k8s-app=kube-proxy
NAME               READY   STATUS             RESTARTS      AGE
kube-proxy-b4kk4   0/1     CrashLoopBackOff   2 (20s ago)   35s
kube-proxy-hqw8v   0/1     CrashLoopBackOff   2 (21s ago)   34s
kube-proxy-rqszf   0/1     CrashLoopBackOff   2 (21s ago)   35s
```

kube-proxy Pod가 실패하고 있는 것을 확인할 수 있습니다.

#### 4.2. kube-proxy 로그 확인

```bash timeout=30
$ kubectl logs -n kube-system -l k8s-app=kube-proxy
...
E1109 22:18:36.012740       1 proxier.go:634] "Could not create dummy VS" err="no such file or directory" scheduler="r"
E1109 22:18:36.012763       1 server.go:558] "Error running ProxyServer" err="can't use the IPVS proxier: no such file or directory"
E1109 22:18:36.012808       1 run.go:74] "command failed" err="can't use the IPVS proxier: no such file or directory"
```

로그를 보면 IPVS 구성 문제가 있음을 알 수 있습니다.

:::info
IPVS(IP Virtual Server)는 패킷 처리에 해시 테이블을 사용하는 kube-proxy의 대체 모드로, 대규모 클러스터에서 더 나은 성능을 제공합니다.
:::

### 근본 원인

kube-proxy의 IPVS 모드 잘못된 구성으로 인해 Pod가 실패하고 있습니다. kube-proxy가 실패하면 kube-dns를 포함한 서비스에 대한 ClusterIP 규칙을 설정할 수 없어 클러스터 전체의 DNS 확인이 중단됩니다.

### 해결 방법

이 문제를 해결하기 위해 kube-proxy 구성을 기본 모드인 **iptables**로 롤백하겠습니다.

:::info
IPVS 모드에 대한 자세한 내용은 [Running kube-proxy in IPVS Mode](https://docs.aws.amazon.com/eks/latest/best-practices/ipvs.html)를 참조하세요.
:::

AWS CLI를 사용하여 기본 kube-proxy 애드온 구성을 적용합니다. 빈 구성을 전달하면 기본 kube-proxy iptables 모드가 적용됩니다:

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

kube-proxy Pod를 재배포하고 업데이트가 완료될 때까지 기다립니다:

```bash timeout=180 wait=5
$ kubectl -n kube-system delete pod -l "k8s-app=kube-proxy"
$ aws eks wait addon-active --cluster-name $EKS_CLUSTER_NAME --region $AWS_REGION  --addon-name kube-proxy
```

그런 다음 kube-proxy Pod가 실행 중인지 확인합니다:

```bash timeout=30
$ kubectl get pod -n kube-system -l k8s-app=kube-proxy
NAME               READY   STATUS    RESTARTS   AGE
kube-proxy-8c4t9   1/1     Running   0          3m13s
kube-proxy-fkr7m   1/1     Running   0          3m13s
kube-proxy-nttzw   1/1     Running   0          3m13s
```

마지막으로 kube-proxy 로그에서 오류가 있는지 확인합니다:

```bash timeout=30
$ kubectl logs -n kube-system -l k8s-app=kube-proxy
...
I1109 22:33:34.994403       1 proxier.go:799] "SyncProxyRules complete" elapsed="63.815782ms"
I1109 22:33:34.994427       1 proxier.go:805] "Syncing iptables rules"
I1109 22:33:35.035283       1 proxier.go:1494] "Reloading service iptables data" numServices=0 numEndpoints=0 numFilterChains=5 numFilterRules=3 numNATChains=4 numNATRules=5
I1109 22:33:35.099387       1 proxier.go:799] "SyncProxyRules complete" elapsed="104.958328ms"
```

### 다음 단계

kube-proxy 구성 문제를 해결하여 애플리케이션 Pod와 kube-dns 서비스를 통한 CoreDNS 간의 적절한 통신을 보장했습니다.

다음 실습에서 최종 문제 해결 단계를 진행하겠습니다.

