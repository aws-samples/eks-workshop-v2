---
title: Amazon EBS
sidebar_position: 30
sidebar_custom_props: { "module": true }
description: "Amazon Elastic Block Store による Amazon Elastic Kubernetes Service 上のワークロード向けの高性能ブロックストレージ。"
kiteTranslationSourceHash: 51097ba837433f254d6682043e2d4996
---

::required-time

:::tip 始める前に
このセクションのために環境を準備してください：

```bash timeout=300 wait=30
$ prepare-environment fundamentals/storage/ebs
```

これにより、ラボ環境に以下の変更が適用されます：

- EBS CSIドライバーアドオンに必要なIAMロールを作成する

これらの変更を適用するTerraformは[こちら](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/fundamentals/storage/ebs/.workshop/terraform)で確認できます。

:::

[Amazon Elastic Block Store](https://aws.amazon.com/ebs/)は、使いやすく、スケーラブルで、高性能なブロックストレージサービスです。ユーザーに永続ボリューム（不揮発性ストレージ）を提供します。永続ストレージにより、ユーザーはデータを削除することを決定するまで、そのデータを保存することができます。

このラボでは、以下の概念について学びます：

- Kubernetes StatefulSets
- EBS CSIドライバー
- EBSボリュームを使用したStatefulSet

