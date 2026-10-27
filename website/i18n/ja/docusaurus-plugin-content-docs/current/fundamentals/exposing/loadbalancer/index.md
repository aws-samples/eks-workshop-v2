---
title: "ロードバランサー"
chapter: true
sidebar_position: 30
sidebar_custom_props: { "module": true }
description: "AWSロードバランサーを管理して、Amazon Elastic Kubernetes Serviceのワークロードにトラフィックをルーティングします。"
tmdTranslationSourceHash: 5fe89f9417b0d4e5f28d697514c08408
---

::required-time

:::tip 始める前に
このセクションの環境を準備してください：

```bash timeout=300 wait=30
$ prepare-environment exposing/load-balancer
```

これにより、ラボ環境に以下の変更が適用されます：

- AWS Load Balancer Controllerに必要なIAMロールを作成します

これらの変更を適用するTerraformは[こちら](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/exposing/load-balancer/.workshop/terraform)で確認できます。

:::

Kubernetesはサービスを使用してPodをクラスター外に公開します。AWSでサービスを使用する最も一般的な方法の1つは、`LoadBalancer`タイプを使用することです。サービス名、ポート、ラベルセレクタを宣言するシンプルなYAMLファイルを使用することで、クラウドコントローラーが自動的にロードバランサーをプロビジョニングします。

```yaml
apiVersion: v1
kind: Service
metadata:
  name: search-svc # サービスの名前
spec:
  # HIGHLIGHT
  type: LoadBalancer
  selector:
    app: SearchApp # PodはApp=SearchAppというラベルでデプロイされています
  ports:
    - port: 80
```

アプリケーションの前にロードバランサーを配置する方法がシンプルなため、これは素晴らしいことです。サービス仕様は長年にわたってアノテーションと追加設定で拡張されてきました。もう1つの選択肢は、Ingressルールとイングレスコントローラーを使用して、外部トラフィックをKubernetes Podにルーティングすることです。

![インターネット向けNetwork Load Balancerがポート80でTCPリスナーを持ち、登録された各EC2ワーカーノードのNodePortに転送し、kube-proxyがui Podへの接続をリレーする様子](/docs/fundamentals/exposing/loadbalancer/ui-nlb-instance.webp)

このチャプターでは、レイヤー4 Network Load Balancerを使用して、EKSクラスターで実行されているアプリケーションをインターネットに公開する方法を紹介します。

