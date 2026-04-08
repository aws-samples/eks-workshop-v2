---
title: "Amazon GuardDuty for EKS"
sidebar_position: 50
sidebar_custom_props: { "module": true }
description: "Detect potentially suspicious activity in Amazon Elastic Kubernetes Service clusters with Amazon GuardDuty."
tmdTranslationSourceHash: 1e21a74b10c998bd34364bedd021d9eb
---

::required-time{estimatedLabExecutionTimeMinutes="20"}

:::tip 始める前に
このセクションの環境を準備してください：

```bash timeout=300 wait=30
$ prepare-environment
```

:::

Amazon GuardDutyは、AWS アカウント、ワークロード、およびAmazon Simple Storage Service (Amazon S3) に保存されたデータを継続的に監視し保護することを可能にする脅威検出サービスを提供します。GuardDutyは、AWS CloudTrailイベント、Amazon Virtual Private Cloud (VPC) フローログ、ドメインネームシステム (DNS) ログで見つかるアカウントとネットワークアクティビティから生成されたメタデータの連続的なストリームを分析します。GuardDutyはまた、既知の悪意のあるIPアドレスなどの統合された脅威インテリジェンス、異常検出、および機械学習 (ML) を利用して、より正確に脅威を特定します。

Amazon GuardDutyを使用すると、AWS アカウント、ワークロード、およびAmazon S3に保存されたデータを簡単に継続的に監視することができます。GuardDutyはリソースから完全に独立して動作するため、ワークロードのパフォーマンスや可用性に影響を与えるリスクはありません。このサービスは統合された脅威インテリジェンス、異常検出、およびMLを備えた完全マネージドサービスです。Amazon GuardDutyは、既存のイベント管理およびワークフローシステムと簡単に統合できる詳細かつ実用的なアラートを提供します。前払いコストはなく、分析されたイベントに対してのみ支払いを行い、追加のソフトウェアのデプロイや脅威インテリジェンスフィードのサブスクリプションは必要ありません。

GuardDutyにはEKSに対する2つの保護カテゴリがあります：

1. EKS監査ログモニタリングは、Kubernetes監査ログアクティビティを使用してEKSクラスター内の潜在的に疑わしいアクティビティを検出するのに役立ちます
1. EKSランタイムモニタリングは、AWS環境内のAmazon Elastic Kubernetes Service (Amazon EKS) ノードおよびコンテナのランタイム脅威検出カバレッジを提供します

このセクションでは、実践的な例を通じて両方の保護タイプを見ていきます。
