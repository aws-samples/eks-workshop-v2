---
title: "ワークロードログへのアクセス"
sidebar_position: 90
description: "Amazon Elastic Kubernetes Service 上で実行されている Pod からワークロードログをキャプチャします。"
tmdTranslationSourceHash: 'da925ddc830e75594e43b7f6ebb12cf5'
---

:::tip セットアップされているもの
Amazon EKS Auto Mode クラスターは Fluent Bit ログ収集エージェントで構成されています。
:::

モダンアプリケーションのアーキテクチャのゴールドスタンダードを提供する [Twelve-Factor App マニフェスト](https://12factor.net/)によると、コンテナ化されたアプリケーションは[ログを stdout と stderr に出力する](https://12factor.net/logs)べきです。これは Kubernetes でもベストプラクティスと考えられています。

アプリケーションログは、開発者がアプリケーションの動作をデバッグする必要があるときの最良の友です。しかし、Kubernetes はすぐに使えるログの収集と保存のネイティブソリューションを提供していません。コンテナランタイムが JSON 形式でログをローカルファイルシステムに保存するように設定するだけです。Docker などのコンテナランタイムは、コンテナの `stdout` と `stderr` ストリームをロギングドライバーにリダイレクトします。Kubernetes では、コンテナログはノード上の `/var/log/pods/*.log` に書き込まれます。これらのログは `kubectl logs myapp` コマンドを使用してアクセスできます。ここで `myapp` はクラスター内で実行されている Pod または Deployment です。しかし、この方法でログにアクセスすることは、本番環境ではスケーラブルではありません。そのためには、Fluent Bit のようなクラスター全体のログコレクターシステムが必要です。このシステムは、ノード上のこれらのログファイルを tail して、CloudWatch のようなログ保持および検索システムにログを送信できます。これらのログコレクターシステムは通常、ワーカーノード上で DaemonSet として実行されます。

このラボでは、ログエージェントである Fluent Bit を設定して、EKS のノードからアプリケーションログを収集し、CloudWatch Logs に送信する方法を示します。

:::info
CDK Observability Accelerator を使用している場合は、[AWS for Fluent Bit Addon](https://aws-quickstart.github.io/cdk-eks-blueprints/addons/aws-for-fluent-bit/) をご確認ください。AWS for FluentBit アドオンは、CloudWatch、Amazon Kinesis、AWS OpenSearch などの複数の AWS 送信先にログを転送するように構成できます。
:::

