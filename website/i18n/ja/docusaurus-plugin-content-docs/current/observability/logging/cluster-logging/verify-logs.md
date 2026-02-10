---
title: "CloudWatchでの閲覧"
sidebar_position: 30
tmdTranslationSourceHash: 4dbd2fb1e2dae8c3a7e9056378720d42
---

CloudWatch Logsコンソールでログを確認してみましょう：

<ConsoleButton url="https://console.aws.amazon.com/cloudwatch/home?#logsV2:log-groups" service="cloudwatch" label="CloudWatchコンソールを開く"/>

**/aws/eks**プレフィックスでフィルタリングし、ログを確認したいクラスターを選択します：

![クラスターロググループ](/docs/observability/logging/cluster-logging/logging-cluster-cw-loggroup.webp)

ロググループ内に多数のログストリームが表示されます：

![ログストリーム](/docs/observability/logging/cluster-logging/logging-cluster-cw-logstream.webp)

これらのログストリームのいずれかを選択すると、EKSコントロールプレーンからCloudWatch Logsに送信されているエントリを確認できます。
