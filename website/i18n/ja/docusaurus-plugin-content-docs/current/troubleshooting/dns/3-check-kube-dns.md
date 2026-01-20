---
title: "kube-dnsサービスの確認"
sidebar_position: 53
kiteTranslationSourceHash: ac41b853a5d83893ed638b730b903e72
---

Kubernetesでは、ポッドはDNS解決のために設定されたネームサーバーを使用します。ネームサーバーの設定は`/etc/resolv.conf`に保存され、デフォルトではKubernetesがすべてのポッドに対してkube-dnsサービスのClusterIPをネームサーバーとして設定します。

### ステップ1 - ポッドのresolv.confを確認する

まず、ポッド内のネームサーバー設定を確認しましょう：

```bash timeout=30
$ kubectl exec -it -n catalog catalog-mysql-0 -- cat /etc/resolv.conf
search catalog.svc.cluster.local svc.cluster.local cluster.local us-west-2.compute.internal
nameserver 172.20.0.10
options ndots:5
```

### ステップ2 - kube-dnsサービスのIPを確認する

次に、このIPがkube-dnsサービスのClusterIPと一致することを確認しましょう：

```bash timeout=30
$ kubectl get svc kube-dns -n kube-system
NAME       TYPE        CLUSTER-IP    EXTERNAL-IP   PORT(S)                  AGE
kube-dns   ClusterIP   172.20.0.10   <none>        53/UDP,53/TCP,9153/TCP   22d
```

ネームサーバーのIPはkube-dnsサービスのClusterIPと一致しており、これは正しい設定です。

### ステップ3 - kube-dnsサービスのエンドポイントを確認する

次に、kube-dnsサービスがCoreDNSポッドにトラフィックを適切にルーティングするように設定されていることを確認します：

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

これらのエンドポイントをCoreDNSポッドのIPと比較します：

```bash timeout=30
$ kubectl get pod -l k8s-app=kube-dns -n kube-system -o wide
NAME                       READY   STATUS    RESTARTS   AGE   IP             ...
CoreDNS-787cb67946-72sqg   1/1     Running   0          18h   10.42.122.16   ...
CoreDNS-787cb67946-gtddh   1/1     Running   0          22d   10.42.153.96   ...
```

サービスエンドポイントはCoreDNSポッドのIPと一致しており、サービス設定が適切であることを確認できます。

:::note
あなたの環境では異なるIPが表示されるでしょう。重要なのはサービスエンドポイントがCoreDNSポッドのIPと一致していることです。
:::

### ステップ4 - kube-proxyポッドを確認する

#### 4.1. kube-proxyの機能を確認する

kube-proxyはクラスター内のサービスルーティングを管理します。kube-dnsサービスからCoreDNSポッドへのDNSトラフィックのルーティングを担当しています。kube-proxyポッドのステータスを確認しましょう：

```bash timeout=30
$ kubectl get pod -n kube-system -l k8s-app=kube-proxy
NAME               READY   STATUS             RESTARTS      AGE
kube-proxy-b4kk4   0/1     CrashLoopBackOff   2 (20s ago)   35s
kube-proxy-hqw8v   0/1     CrashLoopBackOff   2 (21s ago)   34s
kube-proxy-rqszf   0/1     CrashLoopBackOff   2 (21s ago)   35s
```

kube-proxyポッドが失敗していることがわかります。

#### 4.2. kube-proxyのログを調査する

```bash timeout=30
$ kubectl logs -n kube-system -l k8s-app=kube-proxy
...
E1109 22:18:36.012740       1 proxier.go:634] "Could not create dummy VS" err="no such file or directory" scheduler="r"
E1109 22:18:36.012763       1 server.go:558] "Error running ProxyServer" err="can't use the IPVS proxier: no such file or directory"
E1109 22:18:36.012808       1 run.go:74] "command failed" err="can't use the IPVS proxier: no such file or directory"
```

ログはIPVS設定の問題を示しています。

:::info
IPVS（IP Virtual Server）は、kube-proxyの代替モードで、パケット処理にハッシュテーブルを使用し、大規模クラスターでより良いパフォーマンスを提供します。
:::

### 根本原因

kube-proxyのIPVSモードの設定ミスがポッドの失敗を引き起こしています。kube-proxyが失敗すると、kube-dnsを含むサービスのClusterIPルールを設定できなくなり、クラスター全体のDNS解決が中断されます。

### 解決策

この問題を修正するために、kube-proxyの設定をデフォルトモードである**iptables**に戻します。

:::info
IPVSモードの詳細については、[IPVSモードでのkube-proxyの実行](https://docs.aws.amazon.com/eks/latest/best-practices/ipvs.html)を参照してください。
:::

AWS CLIを使用してデフォルトのkube-proxyアドオン設定を適用します。空の設定を渡すと、デフォルトのkube-proxy iptablesモードが適用されることに注意してください：

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

kube-proxyポッドを再デプロイし、更新が完了するのを待ちます：

```bash timeout=180 wait=5
$ kubectl -n kube-system delete pod -l "k8s-app=kube-proxy"
$ aws eks wait addon-active --cluster-name $EKS_CLUSTER_NAME --region $AWS_REGION  --addon-name kube-proxy
```

kube-proxyポッドが実行されていることを確認します：

```bash timeout=30
$ kubectl get pod -n kube-system -l k8s-app=kube-proxy
NAME               READY   STATUS    RESTARTS   AGE
kube-proxy-8c4t9   1/1     Running   0          3m13s
kube-proxy-fkr7m   1/1     Running   0          3m13s
kube-proxy-nttzw   1/1     Running   0          3m13s
```

最後に、kube-proxyのログにエラーがないか確認します：

```bash timeout=30
$ kubectl logs -n kube-system -l k8s-app=kube-proxy
...
I1109 22:33:34.994403       1 proxier.go:799] "SyncProxyRules complete" elapsed="63.815782ms"
I1109 22:33:34.994427       1 proxier.go:805] "Syncing iptables rules"
I1109 22:33:35.035283       1 proxier.go:1494] "Reloading service iptables data" numServices=0 numEndpoints=0 numFilterChains=5 numFilterRules=3 numNATChains=4 numNATRules=5
I1109 22:33:35.099387       1 proxier.go:799] "SyncProxyRules complete" elapsed="104.958328ms"
```

### 次のステップ

kube-proxyの設定問題を解決し、アプリケーションポッドとCoreDNSの間でkube-dnsサービスを介した適切な通信を確保しました。

次のラボで最終的なトラブルシューティングステップに進みましょう。
