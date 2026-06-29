---
title: EBSを使用したワークロードストレージの追加
sidebar_position: 40
description: "Amazon Elastic Block Storeを使用したAmazon Elastic Kubernetes Service上のワークロード向けの永続的なブロックストレージ。"
tmdTranslationSourceHash: 7320f317c9f0a3a5c148c680491d7102
---

:::tip セットアップ済みの内容
Amazon EKS Auto Modeクラスターには**Amazon EBS CSI Driver**が含まれており、永続的なブロックストレージボリュームの動的プロビジョニングが可能です。
:::

[Amazon Elastic Block Store](https://docs.aws.amazon.com/ebs/latest/userguide/what-is-ebs.html) (Amazon EBS) は、Amazon EC2およびAmazon EKSで使用するための永続的なブロックストレージボリュームを提供します。EBSボリュームは高可用性で信頼性の高いストレージであり、同じアベイラビリティーゾーン内で実行中のインスタンスにアタッチできます。

Amazon EKS Auto Modeでは、EBS CSI Driverが事前にインストールされ、AWSによって管理されているため、手動でのインストールや設定は不要です。

このラボでは、以下を実施します：

- EBSによる永続的なブロックストレージについて学習する
- catalog MySQLデータベースを永続的なEBSボリュームを使用するように設定する
- Pod再起動後のデータ永続性を検証する

この実践的な体験を通じて、永続的なストレージソリューションのためにEKS Auto ModeでAmazon EBSを効果的に使用する方法を学びます。

