---
title: "Podロギング"
sidebar_position: 10
sidebar_custom_props: { "module": true }
description: "Amazon Elastic Kubernetes Serviceで実行されているPodからのワークロードログをキャプチャします。"
kiteTranslationSourceHash: 676f52319b1751dd8b4cb6f85ffdaf46
---

::required-time

:::tip 始める前に
このセクションの環境を準備してください：

```bash timeout=300 wait=30
$ prepare-environment observability/logging/pods
```

これにより、ラボ環境に以下の変更が適用されます：

- Amazon EKSクラスターにAWS for Fluent Bitをインストール

これらの変更を適用するTerraformは[こちら](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/observability/logging/pods/.workshop/terraform)で確認できます。
:::

モダンアプリケーションの設計原則を提供する[Twelve-Factor Appマニフェスト](https://12factor.net/)によれば、コンテナ化されたアプリケーションは[ログをstdoutとstderrに出力する](https://12factor.net/logs)べきです。これはKubernetesでもベストプラクティスとされており、クラスターレベルのログ収集システムはこの前提に基づいて構築されています。

Kubernetesのロギングアーキテクチャは、3つの異なるレベルを定義しています：

- 基本レベルのロギング：kubectlを使用してPodのログを取得する機能（例：`kubectl logs myapp` - `myapp`はクラスターで実行されているPod）
- ノードレベルのロギング：コンテナエンジンがアプリケーションの`stdout`と`stderr`からログをキャプチャし、ログファイルに書き込みます。
- クラスターレベルのロギング：ノードレベルのロギングを基盤として、各ノードでログキャプチャエージェントが実行されます。エージェントはローカルファイルシステムからログを収集し、ElasticsearchやCloudWatchなどの集中ログ保存先に送信します。エージェントは次の2種類のログを収集します：
  - ノード上のコンテナエンジンによってキャプチャされたコンテナログ。
  - システムログ。

Kubernetes自体は、ログを収集して保存するためのネイティブソリューションを提供していません。コンテナランタイムを設定して、ローカルファイルシステム上にJSON形式でログを保存します。Dockerのようなコンテナランタイムはコンテナのstdoutとstderrストリームをロギングドライバーにリダイレクトします。Kubernetesでは、コンテナログはノード上の`/var/log/pods/*.log`に書き込まれます。Kubeletとコンテナランタイムは独自のログを`/var/logs`またはsystemdを使用するオペレーティングシステムではjournaldに書き込みます。その後、Fluentdのようなクラスター全体のログコレクターシステムがノード上のこれらのログファイルを監視し、保存のためにログを送信できます。これらのログコレクターシステムは通常、ワーカーノード上でDaemonSetとして実行されます。

このラボでは、EKSのノードからログを収集してCloudWatch Logsに送信するためのログエージェントの設定方法を示します。

:::info
CDK Observability Acceleratorを使用している場合は、[AWS for Fluent Bit Addon](https://aws-quickstart.github.io/cdk-eks-blueprints/addons/aws-for-fluent-bit/)をチェックしてください。AWS for FluentBitアドオンは、CloudWatch、Amazon Kinesis、およびAWS OpenSearchを含む複数のAWS送信先にログを転送するように構成できます。
:::
