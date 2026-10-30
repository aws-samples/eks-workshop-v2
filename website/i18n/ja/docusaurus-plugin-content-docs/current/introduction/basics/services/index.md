---
title: Service
sidebar_position: 40
tmdTranslationSourceHash: 7e89c1c4a77a0ed93376ebbcda1863c1
---

# Service

**Service** は、Pod にアクセスするための安定したネットワークエンドポイントを提供します。Pod は一時的なもので頻繁に作成/削除される可能性があるため、Service は信頼性の高い通信のために一貫した DNS 名と IP アドレスを提供します。

#### Service が重要な理由:
Pod は作成と削除を繰り返すため、クライアントは Pod に直接接続することができません。Service は以下を実現します:
- **安定したネットワーキングの提供:** Pod が変更されても IP と DNS 名は同じままです。
- **負荷分散の提供:** 正常な Pod 間でリクエストを自動的に分散します
- **サービスディスカバリの実現:** 他のコンポーネントは名前で Service に到達できます
- **Pod の抽象化の提供:** クライアントは個々の Pod の IP を知る必要がありません
- **自動更新の処理:** Pod が作成または削除されるとエンドポイントを調整します

このラボでは、小売ストアの catalog コンポーネントの Service を作成し、Service が Pod 間の通信をどのように実現するかを探ります。

### Service タイプ

Kubernetes は、さまざまなユースケースに対応する異なる Service タイプを提供します:

| タイプ | 目的 | アクセス |
|------|---------|--------|
| **ClusterIP** | クラスター内部通信 | クラスターのみ |
| **NodePort** | ノードポート経由の外部アクセス | 外部 |
| **LoadBalancer** | クラウドロードバランサー経由の外部アクセス | 外部 |
| **ExternalName** | 外部 DNS 名へのマッピング | 外部 |

:::info
**LoadBalancer Service** に関する専用のラボは、このワークショップの後半で利用できます。そこでは、クラウドロードバランサーを使用して Service を外部に公開する方法を学習します。
:::

### Service の作成

小売ストアの UI Service を見てみましょう:

::yaml{file="manifests/base-application/ui/service.yaml" paths="kind,metadata.name,spec.type,spec.ports,spec.selector" title="service.yaml"}

1. `kind: Service`: Service リソースを作成します
2. `metadata.name`: Service の名前 (ui)
3. `spec.type`: Service タイプ (内部アクセス用の ClusterIP)
4. `spec.ports`: Service から Pod へのポートマッピング
5. `spec.selector`: どの Pod がトラフィックを受信するかを選択します

Service をデプロイします:
```bash hook=ready
$ kubectl apply -k ~/environment/eks-workshop/modules/introduction/basics/services/
```

### Service が Pod に接続する方法

Service は特定の Pod を直接認識しているわけではありません。代わりに、**ラベルセレクター**を使用して、トラフィックを受信すべき Pod を動的に検索します。これにより、柔軟で疎結合な関係が構築されます。

**仕組みは次のとおりです:**

1. **Pod はラベルを持っています** - Pod を説明するキーと値のペア
2. **Service はセレクターを持っています** - Pod ラベルに一致する基準  
3. **Kubernetes が自動的に接続します** - セレクターに一致する Pod がエンドポイントになります

UI Service でこれを実際に見てみましょう:

```bash
# Service セレクターを確認
$ kubectl get service -n ui ui -o jsonpath='{.spec.selector}' | jq
{
  "app.kubernetes.io/component": "service",
  "app.kubernetes.io/instance": "ui",
  "app.kubernetes.io/name": "ui"
}
```

次に、一致するラベルを持つ Pod を確認します:
```bash
# 一致するラベルを持つ Pod を検索
$ kubectl get pod -n ui -l app.kubernetes.io/component=service -o jsonpath='{.items[0].metadata.labels}{"\n"}' | jq 
{
  "app.kubernetes.io/component": "service",
  "app.kubernetes.io/created-by": "eks-workshop",
  "app.kubernetes.io/instance": "ui",
  "app.kubernetes.io/name": "ui",
  "pod-template-hash": "5989474687"
}
```

UI Pod が Service セレクターに一致するラベルを持っていることがわかります。これが、Service がどの Pod にトラフィックを送信すべきかを知る方法です。

**この関係は動的です:**
- 一致するラベルを持つ新しい Pod が起動すると、自動的に Service のエンドポイントになります
- Pod が削除されると、自動的に Service から削除されます
- Pod のラベルを変更すると、Service に追加または削除できます

このラベルベースのシステムは以下を意味します:
- **Service は任意のワークロードコントローラーと連携します** (Deployment、StatefulSet など)
- **Pod は複数の Service に属することができます** 異なるセレクターに一致する場合
- **Service は自動的に適応します** Pod がスケールアップまたはダウンするにつれて

### Service の確認

Service のステータスを確認します:
```bash
$ kubectl get service -n ui
NAME   TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
ui     ClusterIP   172.20.83.84    <none>        80/TCP    15m
```

Service のエンドポイント (実際の Pod IP) を表示します:
```bash
$ kubectl get endpoints -n ui ui
NAME   ENDPOINTS           AGE
ui     10.42.1.15:8080     15m
```
> これは、どの Pod がトラフィックを受信するかを示しています

詳細な Service 情報を取得します:
```bash
$ kubectl describe service -n ui ui
Name:                     ui
Namespace:                ui
Labels:                   app.kubernetes.io/component=service
                          app.kubernetes.io/created-by=eks-workshop
                          app.kubernetes.io/instance=ui
                          app.kubernetes.io/name=ui
Annotations:              <none>
Selector:                 app.kubernetes.io/component=service,app.kubernetes.io/instance=ui,app.kubernetes.io/name=ui
Type:                     ClusterIP
IP Family Policy:         SingleStack
IP Families:              IPv4
IP:                       172.16.88.252
IPs:                      172.16.88.252
Port:                     http  80/TCP
TargetPort:               http/TCP
Endpoints:                10.42.129.33:8080
Session Affinity:         None
Internal Traffic Policy:  Cluster
Events:                   <none>
```

### サービスディスカバリ

Service は、DNS 名を通じた自動的なサービスディスカバリを実現します:

**完全な DNS 名の形式:**
```
<service-name>.<namespace>.svc.cluster.local
```

**小売ストアからの例:**
- `ui.ui.svc.cluster.local`
- `catalog.catalog.svc.cluster.local`
- `carts.carts.svc.cluster.local`

**同じ Namespace 内での短縮名:**
```
# ui Namespace の Pod から
curl http://ui:80

# 異なる Namespace からは、完全な名前を使用します
curl http://ui.ui.svc.cluster.local:80
```

### Service 通信のテスト

テスト用の Pod を作成して、サービスディスカバリと通信をテストしてみましょう:

```bash
# ネットワークテスト用のテスト Pod を作成
$ kubectl run test-pod --image=curlimages/curl --restart=Never -- sleep 3600
$ kubectl wait --for=condition=ready pod/test-pod --timeout=60s
```

```bash
# クラスター内から DNS 解決をテスト
$ kubectl exec test-pod -- nslookup ui.ui.svc.cluster.local
Server:         172.16.0.10
Address:        172.16.0.10:53


Name:   ui.ui.svc.cluster.local
Address: 172.16.88.252
```

```bash
# HTTP 通信をテスト (Web ページを表示)
$ kubectl exec test-pod -- curl -s http://ui.ui.svc.cluster.local/actuator/info | jq
{
  "pod": {
    "name": "ui-6db5f6bd84-cx4mg"
  }
}
```

### 負荷分散

Service は、セレクターに一致するすべての正常な Pod 間でトラフィックを自動的に分散します:

**UI Deployment をスケールして負荷分散を確認します:**
```bash hook=replicas
$ kubectl scale deployment -n ui ui --replicas=3
```

**Service のエンドポイントがどのように更新されるかを確認します:**
```bash
$ kubectl get endpoints -n ui ui
NAME   ENDPOINTS                                               AGE
ui     10.42.117.212:8080,10.42.129.33:8080,10.42.174.4:8080   11m
```

複数の Pod IP がエンドポイントとしてリストされていることがわかります - Service は、一致するラベルを持つため、新しい Pod を自動的に検出しました。

**負荷分散をテストします:**
```bash
# 複数のリクエストを実行して負荷分散の動作を確認 (1行)
$ for i in $(seq 1 5); do printf "Request %d:" "$i"; kubectl exec test-pod -- curl -s http://ui.ui.svc.cluster.local/actuator/info; echo; sleep 1; done
Request 1:{"pod":{"name":"ui-6db5f6bd84-xgpf4"}}
Request 2:{"pod":{"name":"ui-6db5f6bd84-cx4mg"}}
Request 3:{"pod":{"name":"ui-6db5f6bd84-7bq8w"}}
Request 4:{"pod":{"name":"ui-6db5f6bd84-7bq8w"}}
Request 5:{"pod":{"name":"ui-6db5f6bd84-cx4mg"}}
```

異なる Pod のホスト名にリクエストが分散されていることがわかり、Service がすべての一致する Pod 間で負荷分散を行っていることを示しています。

```bash
# テスト Pod をクリーンアップ
$ kubectl delete pod test-pod
```

## 覚えておくべき重要なポイント

* Service は一時的な Pod に対して安定したネットワークエンドポイントを提供します
* ClusterIP Service はクラスター内部の通信を実現します
* Service はラベルセレクターを使用してターゲット Pod を検索します
* DNS 名は次のパターンに従います: service.namespace.svc.cluster.local
* Service は正常な Pod 間でトラフィックを自動的に負荷分散します
* ポートフォワーディングを使用してローカルで Service をテストします

