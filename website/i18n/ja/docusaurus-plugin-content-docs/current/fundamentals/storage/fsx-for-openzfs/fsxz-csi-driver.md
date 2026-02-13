---
title: FSx for OpenZFS CSI Driver
sidebar_position: 20
tmdTranslationSourceHash: 42b5d289881ac60bdd73a62ac3e2f2d4
---

このセクションに入る前に、メインの[ストレージ](../index.md)セクションで紹介されたKubernetesストレージオブジェクト（ボリューム、永続ボリューム（PV）、永続ボリューム要求（PVC）、動的プロビジョニング、一時ストレージ）に精通しているべきです。

[Amazon FSx for OpenZFS Container Storage Interface (CSI) Driver](https://github.com/kubernetes-sigs/aws-fsx-openzfs-csi-driver)を使用すると、CSIインターフェースを提供することで、AWSで実行されているKubernetesクラスターがAmazon FSx for OpenZFSファイルシステムとボリュームのライフサイクルを管理できるようになり、ステートフルなコンテナ化アプリケーションを実行できます。

以下のアーキテクチャ図は、FSx for OpenZFSをEKS Podの永続ストレージとして使用する方法を示しています：

![FSx for OpenZFSを使用したアセット](/docs/fundamentals/storage/fsx-for-openzfs/fsxz-storage.webp)

EKSクラスターで動的プロビジョニングを使用してAmazon FSx for OpenZFSを利用するには、まずFSx for OpenZFS CSI Driverがインストールされていることを確認する必要があります。このドライバーはCSI仕様を実装しており、コンテナオーケストレーターがAmazon FSx for OpenZFSファイルシステムとボリュームのライフサイクル全体を管理できるようにします。

ラボの準備の一環として、CSIドライバーが適切なAWS APIを呼び出すためのIAMロールが既に作成されています。

Helmを使用してリポジトリを追加し、チャートを使用してFSx for OpenZFS CSIドライバーをインストールします：

```bash timeout=300 wait=60
$ helm repo add aws-fsx-openzfs-csi-driver https://kubernetes-sigs.github.io/aws-fsx-openzfs-csi-driver
$ helm repo update
$ helm upgrade --install aws-fsx-openzfs-csi-driver \
    --namespace kube-system --wait \
    --set "controller.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"="$FSXZ_IAM_ROLE" \
    aws-fsx-openzfs-csi-driver/aws-fsx-openzfs-csi-driver
```

チャートがEKSクラスターに何を作成したか見てみましょう。例えば、クラスター内の各ノードでPodを実行するDaemonSetがあります：

```bash
$ kubectl get daemonset fsx-openzfs-csi-node -n kube-system
NAME                   DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR                 AGE
fsx-openzfs-csi-node   3         3         3       3            3           kubernetes.io/os=linux        52s
```

FSx for OpenZFS CSIドライバーは、動的プロビジョニングと静的プロビジョニングの両方をサポートしています。動的プロビジョニングでは、ドライバーはFSx for OpenZFSファイルシステムと既存のファイルシステム上のボリュームの両方を作成できます。静的プロビジョニングでは、事前に作成されたFSx for OpenZFSファイルシステムまたはボリュームをKubernetes内で使用するためのPersistentVolume（PV）に関連付けることができます。また、ドライバーはNFSマウントオプションの作成、ボリュームスナップショット、ボリュームのサイズ変更もサポートしています。

ラボの準備の一環として、FSx for OpenZFSファイルシステムは既にあなたの使用のために作成されています。このラボでは、FSx for OpenZFSボリュームをデプロイするように設定された[StorageClass](https://kubernetes.io/docs/concepts/storage/storage-classes/)オブジェクトを作成して、動的プロビジョニングを使用します。

FSx for OpenZFSファイルシステムがプロビジョニングされており、FSxマウントポイントへのNFSトラフィックを許可する受信ルールを含む必要なセキュリティグループも一緒に提供されています。後で必要になるそのIDを取得しましょう：

```bash
$ export FSXZ_FS_ID=$(aws fsx describe-file-systems --query "FileSystems[?Tags[?Key=='Name' && Value=='$EKS_CLUSTER_NAME-FSxZ']] | [0].FileSystemId" --output text)
$ echo $FSXZ_FS_ID
fs-0123456789abcdef0
```

FSx for OpenZFS CSIドライバーは、動的プロビジョニングと静的プロビジョニングの両方をサポートしています：

- **動的プロビジョニング**：ドライバーはFSx for OpenZFSファイルシステムと既存のファイルシステム上のボリュームの両方を作成できます。これには、StorageClassパラメータで指定する必要がある既存のAWS FSx for OpenZFSファイルシステムが必要です。
- **静的プロビジョニング**：これも事前に作成されたAWS FSx for OpenZFSファイルシステムまたはボリュームが必要であり、その後、ドライバーを使用してコンテナ内のボリュームとしてマウントできます。

FSx for OpenZFSファイルシステムがワークショップによって作成されたとき、ファイルシステムのルートボリュームも作成されました。ルートボリュームにデータを保存するのではなく、ルートの下に別の子ボリュームを作成し、そこにデータを保存するのがベストプラクティスです。ルートボリュームはワークショップによって作成されたので、そのボリュームIDを取得し、ファイルシステム内にその下に子ボリュームを作成できます。

以下を実行して、ルートボリュームIDを取得し、Kustomizeを使用してボリュームStorageClassに挿入する環境変数に設定します：

```bash
$ export ROOT_VOL_ID=$(aws fsx describe-file-systems --file-system-id $FSXZ_FS_ID | jq -r '.FileSystems[] | .OpenZFSConfiguration.RootVolumeId')
$ echo $ROOT_VOL_ID
fsvol-0123456789abcdef0
```

次に、事前プロビジョニングされたFSx for OpenZFSファイルシステムを使用し、プロビジョニングモードで子ボリュームを作成するように設定された[StorageClass](https://kubernetes.io/docs/concepts/storage/storage-classes/)オブジェクトを作成します。

そのために、`fsxzstorageclass.yaml`ファイルを調べてみましょう：

::yaml{file="manifests/modules/fundamentals/storage/fsxz/storageclass/fsxzstorageclass.yaml" paths="provisioner,parameters.ParentVolumeId, parameters.NfsExports"}

1. FSx for OpenZFS CSIプロビジョナーの`provisioner`パラメータを`fsx.openzfs.csi.aws.com`に設定
2. `ROOT_VOL_ID`環境変数を`ParentVolumeId`パラメータに割り当て
3. `VPC_CIDR`環境変数を`NfsExports`パラメータに挿入

kustomizationを適用します：

```bash
$ kubectl kustomize ~/environment/eks-workshop/modules/fundamentals/storage/fsxz/storageclass \
  | envsubst | kubectl apply -f-
storageclass.storage.k8s.io/fsxz-vol-sc created
```

StorageClassを調べてみましょう。プロビジョナーとしてFSx for OpenZFS CSIドライバーを使用し、先ほどエクスポートしたルートボリュームIDでボリュームプロビジョニングモードに設定されていることに注目してください：

```bash
$ kubectl get storageclass
NAME            PROVISIONER                RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
fsxz-vol-sc     fsx.openzfs.csi.aws.com    Delete          Immediate              false                  8m29s
$ kubectl describe sc fsxz-vol-sc
Name:            fsxz-vol-sc
IsDefaultClass:  No
Annotations:     kubectl.kubernetes.io/last-applied-configuration={"allowVolumeExpansion":false,"apiVersion":"storage.k8s.io/v1","kind":"StorageClass","metadata":{"annotations":{},"name":"fsxz-vol-sc"},"mountOptions":["nfsvers=4.1","rsize=1048576","wsize=1048576","timeo=600","nconnect=16"],"parameters":{"CopyTagsToSnapshots":"false","DataCompressionType":"\"LZ4\"","NfsExports":"[{\"ClientConfigurations\": [{\"Clients\": \"10.42.0.0/16\", \"Options\": [\"rw\",\"crossmnt\",\"no_root_squash\"]}]}]","OptionsOnDeletion":"[\"DELETE_CHILD_VOLUMES_AND_SNAPSHOTS\"]","ParentVolumeId":"\"fsvol-0efa720c2c77956a4\"","ReadOnly":"false","RecordSizeKiB":"128","ResourceType":"volume","Tags":"[{\"Key\": \"Name\", \"Value\": \"eks-workshop-data\"}]"},"provisioner":"fsx.openzfs.csi.aws.com","reclaimPolicy":"Delete"}

Provisioner:           fsx.openzfs.csi.aws.com
Parameters:            CopyTagsToSnapshots=false,DataCompressionType="LZ4",NfsExports=[{"ClientConfigurations": [{"Clients": "10.42.0.0/16", "Options": ["rw","crossmnt","no_root_squash"]}]}],OptionsOnDeletion=["DELETE_CHILD_VOLUMES_AND_SNAPSHOTS"],ParentVolumeId="fsvol-0efa720c2c77956a4",ReadOnly=false,RecordSizeKiB=128,ResourceType=volume,Tags=[{"Key": "Name", "Value": "eks-workshop-data"}]
AllowVolumeExpansion:  False
MountOptions:
  nfsvers=4.1
  rsize=1048576
  wsize=1048576
  timeo=600
  nconnect=16
ReclaimPolicy:      Delete
VolumeBindingMode:  Immediate
Events:             <none>
```

これでFSx for OpenZFS StorageClassと、FSx for OpenZFS CSIドライバーがどのように機能するかを理解したので、次のステップに進む準備ができました。UIコンポーネントを変更して、製品画像を保存するためにKubernetes動的ボリュームプロビジョニングとPersistentVolumeでFSx for OpenZFS `StorageClass`を使用します。
