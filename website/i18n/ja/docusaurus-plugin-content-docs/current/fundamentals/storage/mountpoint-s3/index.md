---
title: Amazon S3用マウントポイント
sidebar_position: 30
sidebar_custom_props: { "module": true }
description: "Amazon Elastic Kubernetes Service上のワークロード向けのサーバーレスオブジェクトストレージをAmazon S3で提供します。"
tmdTranslationSourceHash: 1f3a8f50d3c93f1191e94ec6e7a85a61
---

::required-time

:::tip 始める前に
このセクション用に環境を準備してください：

```bash timeout=1800 wait=30
$ prepare-environment fundamentals/storage/s3
```

これにより、ラボ環境に以下の変更が適用されます：

- Amazon S3用マウントポイントCSIドライバー用のIAMロールの作成
- ワークショップで使用するためのAmazon S3バケットの作成

これらの変更を適用するTerraformは[こちら](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/fundamentals/storage/s3/.workshop/terraform)で確認できます。

:::

[Amazon Simple Storage Service](https://docs.aws.amazon.com/AmazonS3/latest/userguide/Welcome.html)（Amazon S3）は、業界をリードするスケーラビリティ、データの可用性、セキュリティ、およびパフォーマンスを提供するオブジェクトストレージサービスです。あらゆる規模や業界の組織が、データレイク、ウェブサイト、モバイルアプリケーション、バックアップと復元、エンタープライズアプリケーション、IoTデバイス、ビッグデータ分析など、様々なユースケースで任意の量のデータを保存および保護するためにAmazon S3を利用しています。Amazon S3は、特定のビジネス、組織、およびコンプライアンス要件に基づいてデータを最適化、整理、および構成するための包括的な管理機能を提供します。

[Amazon S3用マウントポイント](https://github.com/awslabs/mountpoint-s3)は、[Amazon S3バケットをローカルファイルシステムとしてマウントすることを可能にする](https://aws.amazon.com/blogs/storage/the-inside-story-on-mountpoint-for-amazon-s3-a-high-performance-open-source-file-client/)高スループットのファイルクライアントです。Amazon S3用マウントポイントを使用すると、アプリケーションはopenやreadなどの標準的なファイル操作を通じてAmazon S3に保存されているオブジェクトにアクセスできます。Amazon S3用マウントポイントは、これらの操作をS3オブジェクトAPIコールに透過的に変換し、アプリケーションに馴染みのあるファイルインターフェースを通じてAmazon S3の弾力的なストレージとスループットへのアクセスを提供します。

このラボでは、イメージを保存するためのAmazon S3バケットを作成し、そのバケットをAmazon S3用マウントポイントを使用してマウントし、EKSクラスター用の永続的な共有ストレージを提供します。
