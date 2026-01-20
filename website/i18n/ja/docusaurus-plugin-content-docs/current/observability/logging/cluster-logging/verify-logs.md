---
title: "CloudWatchでの閲覧"
sidebar_position: 30
kiteTranslationSourceHash: ce875064b004c988f04cac2d53d916fd
---

CloudWatch Logsコンソールでログを確認してみましょう：

<ConsoleButton url="https://console.aws.amazon.com/cloudwatch/home?#logsV2:log-groups" service="cloudwatch" label="CloudWatchコンソールを開く"/>

**/aws/eks**プレフィックスでフィルタリングし、ログを確認したいクラスターを選択します：

![クラスターロググループ](./assets/logging-cluster-cw-loggroup.webp)

ロググループ内に多数のログストリームが表示されます：

![ログストリーム](./assets/logging-cluster-cw-logstream.webp)

これらのログストリームのいずれかを選択すると、EKSコントロールプレーンからCloudWatch Logsに送信されているエントリを確認できます。

