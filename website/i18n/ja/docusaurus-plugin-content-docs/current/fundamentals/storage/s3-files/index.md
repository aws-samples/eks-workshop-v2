---
title: Amazon S3 Files
sidebar_position: 35
sidebar_custom_props: { "module": true }
description: "Amazon S3 Files を使用した Amazon Elastic Kubernetes Service 上のワークロード向けの Amazon S3 でバックアップされた共有ファイルシステムストレージ。"
tmdTranslationSourceHash: bcbb34c5f4af8d4ccecfa7c03c72c37e
---

::required-time

:::tip 始める前に
このセクションに向けて環境を準備します:

```bash timeout=300 wait=30
$ prepare-environment fundamentals/storage/s3-files
```

これにより、ラボ環境に以下の変更が加えられます:

- `AmazonS3FilesCSIDriverPolicy` および `AmazonS3FilesClientFullAccess` ポリシーを持つ Amazon EFS CSI ドライバーコントローラー用の IAM role を作成します (S3 Files で使用)
- S3 Files クライアント、S3 読み取り、EFS utils ポリシーをワーカーノードインスタンス role にアタッチして、CSI node daemonset が S3 file system をマウントできるようにします
- バージョニングが有効な Amazon S3 bucket を作成します
- bucket にリンクされた Amazon S3 file system を作成します
- S3 file system のマウントターゲットを作成します

これらの変更を適用する Terraform は[こちら](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/fundamentals/storage/s3-files/.workshop/terraform)で確認できます。

:::

[Amazon S3 Files](https://docs.aws.amazon.com/AmazonS3/latest/userguide/s3-files.html) は、任意の AWS コンピュートリソースを Amazon S3 のデータに直接接続する共有ファイルシステムです。完全なファイルシステムセマンティクスと低レイテンシーパフォーマンスを備えたファイルとして S3 データすべてへの高速で直接的なアクセスを提供し、データが S3 から出ることはありません。Amazon EFS テクノロジーを使用して構築された S3 Files は、ファイルシステムのパフォーマンスとシンプルさに、S3 のスケーラビリティ、耐久性、コスト効率性を組み合わせて提供します。

Mountpoint for Amazon S3 (ファイル操作を S3 API 呼び出しに変換) とは異なり、S3 Files は、read-after-write 整合性、ファイルロック、POSIX パーミッションなどの機能を持つ真の NFS ベースのファイルシステムを提供します。高性能ストレージ層と S3 bucket の間で読み取りをインテリジェントにルーティングし、最適なパフォーマンスを実現します。

このラボでは、以下を行います:

- S3 Files と S3 データへのファイルシステムアクセスの提供方法について学習します
- EKS 上に S3 file system をマウントするために EFS CSI Driver を設定してデプロイします
- Kubernetes deployment で S3 Files を使用した静的プロビジョニングを実装します

このハンズオン体験では、スケーラブルで永続的なストレージソリューション用に Amazon EKS で Amazon S3 Files を効果的に使用する方法を実演します。

:::note
このラボでは**静的プロビジョニング**を使用します。これは、EFS CSI driver の動的プロビジョニングパスが Amazon EFS API をターゲットとしており、S3 Files file system に対してボリュームをプロビジョニングできないためです。Amazon S3 オブジェクトストレージをファイルシステムとして動的かつオンデマンドでプロビジョニングする必要がある場合は、[Mountpoint for Amazon S3](../mountpoint-s3/index.md) モジュールを参照してください。[S3 Files CSI Driver](./s3-files-csi-driver.md) ページでこのトレードオフについて説明しています。
:::

