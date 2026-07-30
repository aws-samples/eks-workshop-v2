---
title: FSx for Lustre CSI Driver
sidebar_position: 20
tmdTranslationSourceHash: bd2142bc015c6a4ac13658804585b22d
---

このセクションに入る前に、メインの [Storage](../index.md) セクションで紹介された Kubernetes ストレージオブジェクト（volumes、persistent volumes (PV)、persistent volume claims (PVC)、dynamic provisioning、ephemeral storage）について理解しておく必要があります。

[Amazon FSx for Lustre Container Storage Interface (CSI) Driver](https://github.com/kubernetes-sigs/aws-fsx-csi-driver) は、Amazon EKS クラスタが Amazon FSx for Lustre ファイルシステムのライフサイクルを管理できるようにする CSI インターフェースを提供します。これにより、高性能な並列ファイルストレージを必要とするステートフルなコンテナ化されたアプリケーションを実行できます。

以下のアーキテクチャ図は、EKS Pod の永続ストレージとして FSx for Lustre を使用する方法を示しています：

![Assets with FSx for Lustre](/docs/fundamentals/storage/fsx-for-lustre/fsxl-storage.webp)

EKS クラスタで Amazon FSx for Lustre を利用するには、FSx for Lustre CSI Driver をインストールする必要があります。このドライバーは CSI 仕様を実装しており、コンテナオーケストレーターが Amazon FSx for Lustre ファイルシステムのライフサイクル全体を管理できるようにします。

ラボの準備の一環として、CSI ドライバーが適切な AWS API を呼び出すための IAM role がすでに作成されています。

FSx for Lustre CSI ドライバーを EKS アドオンとしてインストールします：

```bash timeout=300 wait=60
$ aws eks create-addon --cluster-name $EKS_CLUSTER_NAME \
    --addon-name aws-fsx-csi-driver \
    --service-account-role-arn $FSXL_IAM_ROLE \
    --resolve-conflicts OVERWRITE
$ aws eks wait addon-active --cluster-name $EKS_CLUSTER_NAME \
    --addon-name aws-fsx-csi-driver
```

EKS クラスタでドライバーが実行されていることを確認しましょう：

```bash
$ kubectl get daemonset fsx-csi-node -n kube-system
NAME           DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR            AGE
fsx-csi-node   3         3         3       3            3           kubernetes.io/os=linux   52s
```

FSx for Lustre CSI ドライバーは、dynamic provisioning と static provisioning の両方をサポートしています。dynamic provisioning では、PersistentVolumeClaim (PVC) が作成されるとオンデマンドで新しい FSx for Lustre ファイルシステムがドライバーによって作成されます。static provisioning では、既存の FSx for Lustre ファイルシステムが PersistentVolume (PV) に関連付けられ、Kubernetes 内で使用されます。このラボでは、ラボセットアップの一部として事前にプロビジョニングされたファイルシステムを使用した static provisioning を使用します。

ラボセットアップの一環として、FSx for Lustre ファイルシステムと Lustre トラフィックを許可する必要なセキュリティグループが事前にプロビジョニングされています。後で必要になるファイルシステム ID を取得しましょう：

```bash
$ echo $FSXL_FS_ID
fs-0123456789abcdef0
```

StorageClass のために、ファイルシステムの DNS 名とマウント名も必要です：

```bash
$ export FSXL_DNS_NAME=$(aws fsx describe-file-systems --file-system-ids $FSXL_FS_ID --query "FileSystems[0].DNSName" --output text)
$ export FSXL_MOUNT_NAME=$(aws fsx describe-file-systems --file-system-ids $FSXL_FS_ID --query "FileSystems[0].LustreConfiguration.MountName" --output text)
$ echo "DNS Name: $FSXL_DNS_NAME"
$ echo "Mount Name: $FSXL_MOUNT_NAME"
```

次に、事前に作成された FSx for Lustre ファイルシステムで static provisioning を使用する [StorageClass](https://kubernetes.io/docs/concepts/storage/storage-classes/) を作成します。

`fsxlstorageclass.yaml` ファイルを見てみましょう：

::yaml{file="manifests/modules/fundamentals/storage/fsxl/storageclass/fsxlstorageclass.yaml" paths="provisioner,parameters.subnetId,parameters.securityGroupIds"}

1. FSx for Lustre CSI プロビジョナーの `provisioner` パラメータを `fsx.csi.aws.com` に設定
2. ファイルシステムが存在するサブネット ID を割り当て
3. Lustre トラフィック用のセキュリティグループ ID を割り当て

kustomization を適用します：

```bash
$ kubectl kustomize ~/environment/eks-workshop/modules/fundamentals/storage/fsxl/storageclass \
  | envsubst | kubectl apply -f-
storageclass.storage.k8s.io/fsx-lustre-sc created
```

StorageClass を確認しましょう：

```bash
$ kubectl get storageclass fsx-lustre-sc
NAME            PROVISIONER     RECLAIMPOLICY   VOLUMEBINDINGMODE   ALLOWVOLUMEEXPANSION   AGE
fsx-lustre-sc   fsx.csi.aws.com   Delete          Immediate           false                  10s
```

次に、事前にプロビジョニングされた FSx for Lustre ファイルシステムを参照する PersistentVolume と PersistentVolumeClaim も作成します：

```bash
$ kubectl kustomize ~/environment/eks-workshop/modules/fundamentals/storage/fsxl/pv \
  | envsubst | kubectl apply -f-
persistentvolume/fsxl-pv created
persistentvolumeclaim/fsxl-claim created
```

PVC がバインドされていることを確認しましょう：

```bash
$ kubectl get pvc -n ui fsxl-claim
NAME         STATUS   VOLUME    CAPACITY   ACCESS MODES   STORAGECLASS    AGE
fsxl-claim   Bound    fsxl-pv   1200Gi     RWX            fsx-lustre-sc   10s
```

これで FSx for Lustre StorageClass と FSx for Lustre CSI ドライバーの動作について理解できました。次のステップでは、製品画像を保存するために FSx for Lustre ボリュームを使用するよう UI コンポーネントを変更します。
