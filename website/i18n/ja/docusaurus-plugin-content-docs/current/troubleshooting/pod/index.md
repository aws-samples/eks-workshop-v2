---
title: "Pod Issues"
sidebar_position: 70
description: "Amazon EKSクラスターでのPodに関する一般的な問題のトラブルシューティング"
sidebar_custom_props: { "module": true }
kiteTranslationSourceHash: cc02606a7744b93a170d26c503247f1c
---

::required-time

このセクションでは、Amazon EKSクラスターでコンテナ化されたアプリケーションの実行を妨げる最も一般的なPodの問題（ImagePullBackOffやContainerCreatingの状態で止まっている場合など）のトラブルシューティング方法を学びます。

:::tip 始める前に
このセクションの環境を準備してください：

```bash timeout=600 wait=300
$ prepare-environment troubleshooting/pod
```

この準備により、実験環境に次の変更が適用されます：

- retail-sample-app-uiという名前のECRリポジトリを作成します。
- EC2インスタンスを作成し、インスタンスから小売店のサンプルアプリイメージをタグ0.4.0でECRリポジトリにプッシュします。
- defaultネームスペースにui-privateという名前の新しいデプロイメントを作成します。
- defaultネームスペースにui-newという名前の新しいデプロイメントを作成します。
- EKSクラスターにaws-efs-csi-driverアドオンをインストールします。
- EFSファイルシステムとマウントターゲットを作成します。
- デプロイメント仕様に問題を導入して、この種の問題のトラブルシューティング方法を学びます。
- デプロイメント仕様に問題を導入して、これらの種類の問題のトラブルシューティング方法を学びます。
- defaultネームスペースにefs-claimという名前の永続ボリューム要求を使用して、EFSを永続ボリュームとして活用するefs-appという名前のデプロイメントを作成します。

:::

