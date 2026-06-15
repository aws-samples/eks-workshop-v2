---
title: DaemonSets
sidebar_position: 33
tmdTranslationSourceHash: e602c82c9b66ec1e69017d2ce84be22a
---

# DaemonSets

**DaemonSets** は、クラスター内の**すべてのノード**（または一部のノード）で Pod のコピーが実行されることを保証します。ロギング、監視、ネットワークエージェントなど、すべてのノードで動作する必要があるシステムレベルのサービスに最適です。

主な利点：
- **すべてのノードをカバー** - ノードごとに 1 つの Pod
- **ノードに合わせて自動的にスケール** - 新しいノードには Pod が追加され、削除されたノードからは Pod が削除される
- **システムサービスを実行** - ロギング、監視、ネットワーキングに最適
- **特定のノードをターゲット** - セレクターまたはアフィニティを使用
- **ホストリソースへのアクセス** - ログ、メトリクス、システムファイルなど

## DaemonSets を使用する場合
DaemonSets は、すべてのノードまたは一部のノードで実行する必要があるサービスに最適です：
- **ログコレクター** - Fluentd、Filebeat、Fluent Bit
- **監視エージェント** - Node Exporter、Datadog エージェント、New Relic
- **ネットワークプラグイン** - CNI プラグイン、ロードバランサーコントローラー
- **セキュリティエージェント** - アンチウイルススキャナー、コンプライアンスツール
- **ストレージデーモン** - 分散ストレージエージェント

## DaemonSet のデプロイ

すべてのノードで実行され、ホストファイルシステムからログを収集するシンプルなログコレクター DaemonSet を作成しましょう：

::yaml{file="manifests/modules/introduction/basics/daemonsets/log-collector.yaml" paths="kind,metadata.name,spec.selector,spec.template.spec.containers.0.volumeMounts,spec.template.spec.volumes" title="log-collector.yaml"}

1. `kind: DaemonSet`: DaemonSet コントローラーを作成
2. `metadata.name`: DaemonSet の名前（`log-collector`）
3. `spec.selector`: DaemonSet が Pod を見つける方法（ラベルによる）
4. `spec.template.spec.containers.0.volumeMounts`: コンテナがノードファイルにアクセスする方法
5. `spec.template.spec.volumes`: ノードログにアクセスするためのホストパス

DaemonSet の主な特徴：
- `replicas` フィールドがない - Kubernetes は自動的にノードごとに 1 つの Pod を実行
- ノードが追加または削除されると、Pod が自動的にスケール
- 必要に応じて、`hostPath` ボリュームを使用して Pod がノードファイルにアクセス可能
- 通常はシステムサービス用に `kube-system` namespace にデプロイされますが、他の namespace でも実行可能

DaemonSet をデプロイします：
```bash
$ kubectl apply -f ~/environment/eks-workshop/modules/introduction/basics/daemonsets/log-collector.yaml
```

## DaemonSet の検査

DaemonSet のステータスを確認：
```bash
$ kubectl get daemonset -n kube-system
NAME            DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   AGE
log-collector   3         3         3       3            3           2m
```
> 期待される Pod と現在の Pod を示す出力が表示されます：

すべてのノードで Pod を確認：
```bash
$ kubectl get pods -n kube-system -l app=log-collector -o wide
NAME                  READY   STATUS    NODE           AGE
log-collector-abc12   1/1     Running   ip-10-42-1-1   2m
log-collector-def34   1/1     Running   ip-10-42-2-1   2m
log-collector-ghi56   1/1     Running   ip-10-42-3-1   2m
```
> ノードごとに 1 つの Pod があることに注目してください

## ノードの選択

nodeSelector を使用して特定のノードをターゲットにします：

```yaml
spec:
  template:
    spec:
      nodeSelector:
        node-type: worker
      containers:
      - name: monitoring-agent
        image: monitoring:latest
```

より複雑なルールには nodeAffinity を使用します：

```yaml
spec:
  template:
    spec:
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: kubernetes.io/arch
                operator: In
                values:
                - amd64
```
シンプルなラベルマッチには nodeSelector を、より複雑なスケジューリング要件には nodeAffinity を使用します。

## DaemonSets と他のコントローラーの比較

| コントローラー | 目的 | レプリカ数 | ノード配置 | ユースケース |
|------------|---------|---------------|----------------|----------|
| DaemonSet  | ノードごとに 1 つの Pod | 自動 | すべてのノードまたは一部 | システムサービス |
| Deployment | 複数の交換可能な Pod | 設定可能 | 任意のノード | ステートレスアプリ |
| StatefulSet | 安定したアイデンティティを持つ Pod | 設定可能 | 任意のノード | ステートフルアプリ |

:::info
DaemonSets は、すべてのノードまたは特定のノードセットで実行する必要があるサービスに最適です。
:::

## 覚えておくべき重要なポイント

* DaemonSets は自動的にノードごとに 1 つの Pod を実行
* ロギングや監視などのシステムレベルのサービスに最適
* レプリカ数を指定する必要がない - 自動的に決定される
* hostPath ボリュームを通じてノードリソースにアクセス可能
* ノードセレクターを使用して特定のノードをターゲット化
* ノードが参加/離脱すると、Pod が自動的に追加/削除される
* すべてのノードで一貫したシステム機能を実現するのに最適

