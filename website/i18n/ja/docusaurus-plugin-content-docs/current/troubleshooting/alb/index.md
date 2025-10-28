---
title: "ALB Controller"
chapter: true
sidebar_position: 40
sidebar_custom_props: { "module": true }
kiteTranslationSourceHash: b36bbab8cf13755387c757ff2b77d0d3
---

::required-time

このラボでは、Amazon EKSを使用する際に発生する一般的な問題を探求し、効果的なトラブルシューティング技術を学びます。AWS Load Balancer ControllerとサービスConnectivity問題に焦点を当てた実世界のシナリオを通じて問題解決を行います。Load Balancer Controllerの仕組みについてさらに詳しく知りたい場合は、[基礎モジュール](/docs/fundamentals/)または[AWS LB Controller](https://docs.aws.amazon.com/eks/latest/userguide/aws-load-balancer-controller.html)の公式ドキュメントをご確認ください。

:::tip 始める前に
このセクションの環境を準備します：

```bash timeout=600 wait=10
$ prepare-environment troubleshooting/alb
```
これらの変更を適用するTerraformは[こちら](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/troubleshooting/alb/.workshop/terraform)で確認できます。
:::
:::info

ラボの準備には数分かかることがあり、以下の変更がラボ環境に適用されます：


- サンプルUIアプリケーションのデプロイ
- イングレスリソースの設定
- 初期AWS Load Balancer Controller設定（トラブルシューティング用の意図的な問題を含む）
- 必要なIAMロールとポリシーの作成

:::

## 環境設定の詳細

prepare-environmentスクリプトは、トラブルシューティングが必要な特定の問題を含むいくつかのリソースを作成しました：

- uiネームスペースにUIアプリケーションのデプロイメント
- AWS Load Balancer Controllerを使用するように設定されたイングレスリソース
- IAMロールとポリシー（意図的な設定ミスを含む）
- Kubernetesサービスリソース

これらのコンポーネントは、このモジュールを通じて特定して修正する一般的な実世界の問題で設定されています。

## 取り上げる内容

以下のような問題をトラブルシューティングします：

- ALB作成を妨げるサブネットタグの不足または不正確さ
- Load Balancer Controllerをブロックするアクセス許可の問題
- サービスセレクターの設定ミス
- イングレスバックエンドサービスの問題

## 前提条件

進める前に、以下を確認してください：

- EKSクラスターへのアクセス
- AWS CLIの適切な設定
- kubectlのインストールと設定
- Kubernetesネットワーキング概念の基本的な理解

## 使用するツール

このモジュールを通して、以下のトラブルシューティングツールを使用します：

- Kubernetesリソース検査のためのkubectlコマンド
- AWSリソースの状態確認のためのAWS CLI
- コントローラー診断のためのCloudWatchログ
- アクセス許可検証のためのAWS IAMツール

:::tip 進める前に
prepare-environmentスクリプトの実行から数分後、サービスとイングレスが起動して実行されていることを確認します。

```bash
$ kubectl get svc -n ui
NAME   TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)   AGE
ui     ClusterIP   172.20.224.112   <none>        80/TCP    12d
```

```bash
$ kubectl get ingress -n ui
NAME   CLASS   HOSTS   ADDRESS   PORTS   AGE
ui     alb     *                 80      11m

```

ロードバランサーが実際に作成されていないことを確認しましょう：

```bash
$ aws elbv2 describe-load-balancers --query 'LoadBalancers[?contains(LoadBalancerName, `k8s-ui-ui`) == `true`]'
[]
```

:::
それでは、Application Load Balancerが作成されない理由を調査していきましょう！

