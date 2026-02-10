---
title: "シナリオのセットアップ"
sidebar_position: 51
tmdTranslationSourceHash: 3ec9b4414036461ebd38ff6e6e06b60c
---

クラスター内のDNS解決は、複数の構成オプションの影響を受ける可能性があり、サービス通信を妨げることがあります。このモジュールでは、EKSクラスターでよく遭遇するDNS関連の問題をシミュレートします。

### ステップ1 - 設定スクリプトの実行

このモジュールの問題を導入するために、次のスクリプトを実行します：

```bash timeout=180 wait=5
$ bash ~/environment/eks-workshop/modules/troubleshooting/dns/.workshop/lab-setup.sh
Configuration applied successfully!
```

### ステップ2 - アプリケーションポッドの再起動

次に、アプリケーションポッドを再デプロイします：

```bash timeout=30 wait=30
$ kubectl delete pod -l app.kubernetes.io/created-by=eks-workshop -l app.kubernetes.io/component=service -A
```

すべてのポッドが再作成されるのを待ち、アプリケーションのステータスを確認します。一部のポッドがReadyステータスに到達できず、ErrorまたはCrashLoopBackOffステータスで複数回再起動していることに気づくでしょう：

```bash timeout=30 expectError=true
$ kubectl get pod -l app.kubernetes.io/created-by=eks-workshop -l app.kubernetes.io/component=service -A
NAMESPACE   NAME                              READY   STATUS             RESTARTS      AGE
carts       carts-5475469b7c-gm7kw            0/1     Running            2 (40s ago)   110s
catalog     catalog-5578f9649b-bbrjp          0/1     CrashLoopBackOff   3 (42s ago)   110s
checkout    checkout-84c6769ddd-rvwnv         1/1     Running            0             110s
orders      orders-6d74499d87-lhgwh           0/1     Running            2 (44s ago)   110s
ui          ui-5f4d85f85f-hdhjg               1/1     Running            0             109s
```

### ステップ3 - アプリケーションの問題のトラブルシューティング

#### 3.1. 問題の調査

ポッドが正常に起動しない場合は、`kubectl describe pod`を使用してポッドとコンテナのプロビジョニングの問題を確認できます。Ready状態ではないcatalogポッドのeventsセクションを調べます：

```bash timeout=30 expectError=true
$ kubectl describe pod -l app.kubernetes.io/name=catalog -l app.kubernetes.io/component=service -n catalog
...
Events:
  Type     Reason     Age                    From               Message
  ----     ------     ----                   ----               -------
  Normal   Scheduled  3m47s                  default-scheduler  Successfully assigned catalog/catalog-5578f9649b-bbrjp to ip-10-42-100-65.us-west-2.compute.internal
  Normal   Started    3m16s (x3 over 3m46s)  kubelet            Started container catalog
  Warning  Unhealthy  3m12s (x9 over 3m46s)  kubelet            Readiness probe failed: Get "http://10.42.115.209:8080/health": dial tcp 10.42.115.209:8080: connect: connection refused
  Warning  BackOff    2m55s (x5 over 3m34s)  kubelet            Back-off restarting failed container catalog in pod catalog-5578f9649b-bbrjp_catalog(b5c1c1fa-5db6-4be4-8dcd-0910410f5630)
  Normal   Pulled     2m44s (x4 over 3m46s)  kubelet            Container image "public.ecr.aws/aws-containers/retail-store-sample-catalog:0.4.0" already present on machine
  Normal   Created    2m44s (x4 over 3m46s)  kubelet            Created container catalog
```

イベントは、コンテナは起動するものの、アプリケーションが適切に実行されていないことを示しています。Readinessプローブの失敗がコンテナの再起動をトリガーしています。

#### 3.1. アプリケーションログの確認

アプリケーションが実行されない理由を理解するために、アプリケーションログを確認します：

```bash timeout=30 expectError=true
$ kubectl logs -l app.kubernetes.io/name=catalog -l app.kubernetes.io/component=service -n catalog
2024/10/20 15:19:27 Running database migration...
2024/10/20 15:19:27 Schema migration applied
2024/10/20 15:19:27 Connecting to catalog-mysql:3306/catalog?timeout=5s
2024/10/20 15:19:27 invalid connection config: missing required peer IP or hostname
2024/10/20 15:19:27 Connected
2024/10/20 15:19:27 Connecting to catalog-mysql:3306/catalog?timeout=5s
2024/10/20 15:19:27 invalid connection config: missing required peer IP or hostname
2024/10/20 15:19:32 Error: Unable to connect to reader database dial tcp: lookup catalog-mysql: i/o timeout
2024/10/20 15:19:32 dial tcp: lookup catalog-mysql: i/o timeout
```

ログには、アプリケーションがMySQLデータベースのサービス名（catalog-mysql）を解決しようとした際に、DNS解決タイムアウトのためにデータベースに接続できないことが示されています。

:::info
オプションで、他のReady状態でないポッドのログを確認することもできます。それらも同様のDNS解決の失敗を示しています。
:::

### 次のステップ

以降のセクションでは、DNS解決失敗の根本原因を特定するための重要なトラブルシューティングステップを探ります。
