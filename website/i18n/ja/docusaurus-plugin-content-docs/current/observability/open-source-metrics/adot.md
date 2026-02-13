---
title: "AWS Distro for OpenTelemetry を使用したメトリクスのスクレイピング"
sidebar_position: 10
tmdTranslationSourceHash: 6aa970c5e4f2721d7454114bf1c8dcc1
---

このラボでは、すでに作成されている Amazon Managed Service for Prometheus ワークスペースにメトリクスを保存します。コンソールで確認することができます：

<ConsoleButton url="https://console.aws.amazon.com/prometheus/home#/workspaces" service="aps" label="APS コンソールを開く"/>

ワークスペースを表示するには、左側のコントロールパネルの **All Workspaces** タブをクリックします。**eks-workshop** で始まるワークスペースを選択すると、ルール管理やアラートマネージャーなどのワークスペース内のさまざまなタブを表示できます。

Amazon EKS クラスターからメトリクスを収集するために、`OpenTelemetryCollector` カスタムリソースをデプロイします。EKS クラスターで実行されている ADOT オペレーターは、このリソースの存在や変更を検出し、以下のアクションを実行します：

- Kubernetes API サーバーへの作成、更新、削除リクエストに必要なすべての接続が利用可能であることを確認します。
- `OpenTelemetryCollector` リソース設定でユーザーが指定した方法で ADOT コレクターインスタンスをデプロイします。

まず、ADOT コレクターに必要な権限を与えるリソースを作成しましょう。コレクターが Kubernetes API にアクセスするための権限を与える ClusterRole から始めます：

::yaml{file="manifests/modules/observability/oss-metrics/adot/clusterrole.yaml" paths="rules.0,rules.1,rules.2"}

1. このコア API グループ `""` は、メトリクス収集のために `resources` の下にリストされているコア Kubernetes リソースに `verbs` の下で指定されたアクションを使用してアクセスする権限をロールに与えます
2. この拡張 API グループ `extensions` は、ネットワークトラフィックメトリクス収集のために `verbs` の下で指定されたアクションを使用してイングレスリソースにアクセスする権限をロールに与えます
3. `nonResourceURLs` は、クラスターレベルの運用メトリクス収集のために `verbs` の下で指定されたアクションを使用して、Kubernetes API サーバー上の `/metrics` エンドポイントにアクセスする権限をロールに与えます

マネージド IAM ポリシー `AmazonPrometheusRemoteWriteAccess` を使用して、IAM Roles for Service Accounts を通じてコレクターに必要な IAM 権限を提供します：

```bash
$ aws iam list-attached-role-policies \
  --role-name $EKS_CLUSTER_NAME-adot-collector | jq .
{
  "AttachedPolicies": [
    {
      "PolicyName": "AmazonPrometheusRemoteWriteAccess",
      "PolicyArn": "arn:aws:iam::aws:policy/AmazonPrometheusRemoteWriteAccess"
    }
  ]
}
```

この IAM ロールは、コレクターの ServiceAccount に追加されます：

```file
manifests/modules/observability/oss-metrics/adot/serviceaccount.yaml
```

リソースを作成します：

```bash hook=deploy-adot
$ kubectl kustomize ~/environment/eks-workshop/modules/observability/oss-metrics/adot \
  | envsubst | kubectl apply -f-
$ kubectl rollout status -n other deployment/adot-collector --timeout=120s
```

コレクターの仕様は長すぎて全てを表示できませんが、以下のように確認できます：

```bash
$ kubectl -n other get opentelemetrycollector adot -o yaml
```

より理解しやすくするために、このセクションを分解してみましょう。これが OpenTelemetry コレクター設定です：

```bash
$ kubectl -n other get opentelemetrycollector adot -o jsonpath='{.spec.config}' | jq
```

これは以下の構造を持つ OpenTelemetry パイプラインを設定しています：

- レシーバー
  - [Prometheus レシーバー](https://github.com/open-telemetry/opentelemetry-collector-contrib/blob/main/receiver/prometheusreceiver/README.md) - Prometheus エンドポイントを公開するターゲットからメトリクスをスクレイプするように設計されています
- プロセッサー
  - このパイプラインには含まれていません
- エクスポーター
  - [Prometheus リモートライトエクスポーター](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/exporter/prometheusremotewriteexporter) - AMP のような Prometheus リモートライトエンドポイントにメトリクスを送信します

このコレクターは、1つのコレクターエージェントを実行する Deployment として構成されています：

```bash
$ kubectl -n other get opentelemetrycollector adot -o jsonpath='{.spec.mode}{"\n"}'
```

実行中の ADOT コレクター Pod を調査することで、これを確認できます：

```bash
$ kubectl get pods -n other
NAME                              READY   STATUS    RESTARTS   AGE
adot-collector-6f6b8867f6-lpjb7   1/1     Running   2          11d
```
