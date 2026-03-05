---
title: EFS CSIドライバー
sidebar_position: 20
tmdTranslationSourceHash: e381ce19d4fb30098d1dfe2c70ba6658
---

このセクションに入る前に、メインの[ストレージ](../index.md)セクションで紹介されたKubernetesのストレージオブジェクト（ボリューム、Persistent Volume（PV）、Persistent Volume Claim（PVC）、動的プロビジョニング、一時的ストレージ）について理解しておく必要があります。

[Amazon Elastic File System Container Storage Interface (CSI) Driver](https://github.com/kubernetes-sigs/aws-efs-csi-driver)を使用すると、CSIインターフェースを提供することで、AWSで実行されているKubernetesクラスターがAmazon EFSファイルシステムのライフサイクルを管理できるようになり、ステートフルなコンテナ化されたアプリケーションを実行できます。

次のアーキテクチャ図は、EKS PodのPersistent StorageとしてEFSを使用する方法を示しています：

![Assets with EFS](/docs/fundamentals/storage/efs/efs-storage.webp)

EKSクラスターで動的プロビジョニングを使用してAmazon EFSを利用するには、まずEFS CSI Driverがインストールされていることを確認する必要があります。このドライバーはCSI仕様を実装しており、コンテナオーケストレーターがAmazon EFSファイルシステムのライフサイクル全体を管理できるようにします。

セキュリティの向上と管理の簡素化のために、Amazon EFS CSI driverをAmazon EKSアドオンとして実行できます。必要なIAM roleが既に作成されているため、アドオンのインストールを進めることができます：

```bash timeout=300 wait=60
$ aws eks create-addon --cluster-name $EKS_CLUSTER_NAME --addon-name aws-efs-csi-driver \
  --service-account-role-arn $EFS_CSI_ADDON_ROLE
$ aws eks wait addon-active --cluster-name $EKS_CLUSTER_NAME --addon-name aws-efs-csi-driver
```

アドオンがEKSクラスターに作成したものを確認してみましょう。例えば、クラスター内の各ノードでPodを実行するDaemonSetがあります：

```bash
$ kubectl get daemonset efs-csi-node -n kube-system
NAME           DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR                 AGE
efs-csi-node   3         3         3       3            3           kubernetes.io/os=linux        47s
```

EFS CSI driverは動的プロビジョニングと静的プロビジョニングの両方をサポートしています：

- **動的プロビジョニング**：ドライバーは各PersistentVolumeのアクセスポイントを作成します。これには既存のAWS EFSファイルシステムが必要であり、StorageClassパラメータで指定する必要があります。
- **静的プロビジョニング**：これにも事前に作成されたAWS EFSファイルシステムが必要であり、ドライバーを使用してコンテナ内のボリュームとしてマウントできます。

EFSファイルシステムはすでにプロビジョニングされており、マウントターゲットとEFSマウントポイントへのNFSトラフィックを許可するインバウンドルールを含む必要なセキュリティグループも設定されています。後で使用するためにIDを取得しましょう：

```bash
$ export EFS_ID=$(aws efs describe-file-systems --query "FileSystems[?Name=='$EKS_CLUSTER_NAME-efs-assets'] | [0].FileSystemId" --output text)
$ echo $EFS_ID
fs-061cb5c5ed841a6b0
```

次に、事前にプロビジョニングされたEFSファイルシステムと[EFSアクセスポイント](https://docs.aws.amazon.com/efs/latest/ug/efs-access-points.html)をプロビジョニングモードで使用するように設定された[StorageClass](https://kubernetes.io/docs/concepts/storage/storage-classes/)オブジェクトを作成します。これには`efsstorageclass.yaml`ファイルを使用します。

::yaml{file="manifests/modules/fundamentals/storage/efs/storageclass/efsstorageclass.yaml" paths="provisioner,parameters.fileSystemId"}

1. EFS CSIプロビジョナー用に`provisioner`パラメータを`efs.csi.aws.com`に設定します
2. `filesystemid`パラメータに`EFS_ID`環境変数を注入します

kustomizationを適用します：

```bash
$ kubectl kustomize ~/environment/eks-workshop/modules/fundamentals/storage/efs/storageclass \
  | envsubst | kubectl apply -f-
storageclass.storage.k8s.io/efs-sc created
```

StorageClassを確認してみましょう。プロビジョナーとしてEFS CSI driverを使用し、先ほどエクスポートしたファイルシステムIDを持つEFSアクセスポイントプロビジョニングモードに設定されていることに注目してください：

```bash
$ kubectl get storageclass
NAME            PROVISIONER             RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
efs-sc          efs.csi.aws.com         Delete          Immediate              false                  8m29s
$ kubectl describe sc efs-sc
Name:            efs-sc
IsDefaultClass:  No
Annotations:     kubectl.kubernetes.io/last-applied-configuration={"apiVersion":"storage.k8s.io/v1","kind":"StorageClass","metadata":{"annotations":{},"name":"efs-sc"},"parameters":{"directoryPerms":"700","fileSystemId":"fs-061cb5c5ed841a6b0","provisioningMode":"efs-ap"},"provisioner":"efs.csi.aws.com"}

Provisioner:           efs.csi.aws.com
Parameters:            directoryPerms=700,fileSystemId=fs-061cb5c5ed841a6b0,provisioningMode=efs-ap
AllowVolumeExpansion:  <unset>
MountOptions:          <none>
ReclaimPolicy:         Delete
VolumeBindingMode:     Immediate
Events:                <none>
```

これでEFS StorageClassとEFS CSI driverの仕組みが理解できました。次のステップでは、UIコンポーネントを変更して、Kubernetesの動的ボリュームプロビジョニングとEFS `StorageClass`を使用して、製品画像を保存するためのPersistentVolumeを使用します。

