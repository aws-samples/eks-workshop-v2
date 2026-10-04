---
title: S3 Files CSI ドライバー
sidebar_position: 20
tmdTranslationSourceHash: '338d78cf5da771d84377a42b7c28ad52'
---

このセクションに進む前に、メインの [Storage](../index.md) セクションで紹介された Kubernetes ストレージオブジェクト（ボリューム、Persistent Volume (PV)、Persistent Volume Claim (PVC)、動的プロビジョニング、エフェメラルストレージ）について理解しておく必要があります。

Amazon S3 Files は [Amazon EFS Container Storage Interface (CSI) Driver](https://github.com/kubernetes-sigs/aws-efs-csi-driver)（バージョン 3.0.0 以降）を使用して、Amazon EKS クラスター上に S3 Files ファイルシステムをマウントします。S3 Files は Amazon EFS テクノロジーをベースに構築されており、NFS プロトコルを使用するため、Amazon EFS をサポートする同じドライバーが S3 Files もサポートします。

以下のアーキテクチャ図は、EKS Pod の永続ストレージとして S3 Files を使用する方法を示しています：

![Assets with S3 Files](/docs/fundamentals/storage/s3-files/s3-files-storage.webp)

EKS クラスターで Amazon S3 Files を利用するには、まず EFS CSI Driver がインストールされていることを確認する必要があります。このドライバーは CSI 仕様を実装しており、コンテナオーケストレーターが Amazon EFS と S3 Files ファイルシステムの両方をそのライフサイクル全体で管理できるようにします。

必要な IAM ロールはすでに作成されているため、アドオンのインストールを進めることができます：

```bash timeout=300 wait=60
$ aws eks create-addon --cluster-name $EKS_CLUSTER_NAME --addon-name aws-efs-csi-driver \
  --service-account-role-arn $S3_FILES_CSI_ADDON_ROLE
$ aws eks wait addon-active --cluster-name $EKS_CLUSTER_NAME --addon-name aws-efs-csi-driver
```

アドオンが EKS クラスターに作成したものを確認しましょう。例えば、クラスター内の各ノードで Pod を実行する DaemonSet があります：

```bash
$ kubectl get daemonset efs-csi-node -n kube-system
NAME           DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR                 AGE
efs-csi-node   3         3         3       3            3           kubernetes.io/os=linux        47s
```

EFS CSI ドライバーがインストールされ、実行されていることを確認したので、次に S3 ファイルシステム用のストレージをプロビジョニングする方法と、なぜ静的プロビジョニングを使用するのかを見ていきましょう。

