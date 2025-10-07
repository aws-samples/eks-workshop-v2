---
title: EBS CSI ドライバー
sidebar_position: 20
kiteTranslationSourceHash: 3c32323a8b3db48e3736c40ecaef5fd5
---

このセクションに入る前に、[ストレージ](../index.md)のメインセクションで紹介されたKubernetesのストレージオブジェクト（ボリューム、永続ボリューム（PV）、永続ボリューム要求（PVC）、動的プロビジョニング、一時ストレージ）について理解しておいてください。

[**emptyDir**](https://kubernetes.io/docs/concepts/storage/volumes/#emptydir)は一時的なボリュームの一例で、現在MySQLのStatefulSetで使用していますが、このチャプターでは動的ボリュームプロビジョニングを使用して永続ボリューム（PV）に更新する作業を行います。

[Kubernetes Container Storage Interface（CSI）](https://kubernetes-csi.github.io/docs/)は、ステートフルなコンテナ化されたアプリケーションの実行を支援します。CSIドライバーはCSIインターフェースを提供し、Kubernetesクラスターが永続ボリュームのライフサイクルを管理できるようにします。Amazon EKSはAmazon EBSのCSIドライバーを提供することで、ステートフルなワークロードの実行をより簡単にします。

EKSクラスターで動的プロビジョニングを使用してAmazon EBSボリュームを利用するには、EBS CSIドライバーがインストールされていることを確認する必要があります。[Amazon Elastic Block Store（Amazon EBS）Container Storage Interface（CSI）ドライバー](https://github.com/kubernetes-sigs/aws-ebs-csi-driver)により、Amazon Elastic Kubernetes Service（Amazon EKS）クラスターは永続ボリューム用のAmazon EBSボリュームのライフサイクルを管理できます。

セキュリティを向上させ、作業量を減らすために、Amazon EKSアドオンとしてAmazon EBS CSIドライバーを管理できます。アドオンが必要とするIAMロールは既に作成されているため、アドオンをインストールすることができます：

```bash timeout=300 wait=60
$ aws eks create-addon --cluster-name $EKS_CLUSTER_NAME --addon-name aws-ebs-csi-driver \
  --service-account-role-arn $EBS_CSI_ADDON_ROLE \
  --configuration-values '{"defaultStorageClass":{"enabled":true}}'
$ aws eks wait addon-active --cluster-name $EKS_CLUSTER_NAME --addon-name aws-ebs-csi-driver
```

ここで、アドオンによってEKSクラスターに何が作成されたかを確認してみましょう。例えば、DaemonSetはクラスター内の各ノードでポッドを実行しています：

```bash
$ kubectl get daemonset ebs-csi-node -n kube-system
NAME           DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR            AGE
ebs-csi-node   3         3         3       3            3           kubernetes.io/os=linux   3d21h
```

EKS 1.30以降、EBS CSIドライバーは[Amazon EBS GP3ボリュームタイプ](https://docs.aws.amazon.com/ebs/latest/userguide/general-purpose.html#gp3-ebs-volume-type)を使用して設定されたデフォルトの[StorageClass](https://kubernetes.io/docs/concepts/storage/storage-classes/)オブジェクトを使用します。次のコマンドを実行して確認してください：

```bash
$ kubectl get storageclass
NAME                           PROVISIONER             RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
ebs-csi-default-sc (default)   ebs.csi.aws.com         Delete          WaitForFirstConsumer   true                   96s
gp2                            kubernetes.io/aws-ebs   Delete          WaitForFirstConsumer   false                  9d
```

これでEKSストレージとKubernetesオブジェクトについての理解が深まりました。次のページでは、カタログマイクロサービスのMySQL DBのStatefulSetを修正して、Kubernetesの動的ボリュームプロビジョニングを使用してデータベースファイルの永続ストレージとしてEBSブロックストアボリュームを利用することに焦点を当てます。
