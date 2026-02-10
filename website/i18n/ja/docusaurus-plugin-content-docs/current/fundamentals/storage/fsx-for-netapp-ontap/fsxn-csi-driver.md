---
title: FSx for NetApp ONTAP CSI ドライバー
sidebar_position: 20
tmdTranslationSourceHash: 15cdbda44d1d25a0e88fb88a737efc18
---

このセクションに入る前に、メインの[ストレージ](../index.md)セクションで紹介したKubernetesストレージオブジェクト（ボリューム、永続ボリューム（PV）、永続ボリューム要求（PVC）、動的プロビジョニング、一時ストレージ）について理解しておくべきです。

[Amazon FSx for NetApp ONTAP Container Storage Interface (CSI) ドライバー](https://github.com/NetApp/trident)は、AWSで実行されているKubernetesクラスターがAmazon FSx for NetApp ONTAPファイルシステムのライフサイクルを管理できるようにするCSIインターフェースを提供することで、ステートフルなコンテナ化アプリケーションを実行できるようにします。

次のアーキテクチャ図は、FSx for NetApp ONTAPをEKSポッドの永続ストレージとして使用する方法を示しています：

![FSx for NetApp ONTAPを使用したアセット](/docs/fundamentals/storage/fsx-for-netapp-ontap/fsxn-storage.webp)

EKSクラスターで動的プロビジョニングを使用してAmazon FSx for NetApp ONTAPを利用するには、まずFSx for NetApp ONTAP CSIドライバーがインストールされていることを確認する必要があります。このドライバーはCSI仕様を実装しており、コンテナオーケストレーターがAmazon FSx for NetApp ONTAPファイルシステムのライフサイクル全体を管理できるようにします。

`helm`を使用してAmazon FSxN for NetApp ONTAP Trident CSIドライバーをインストールできます。ワークショップの準備の一環としてすでに作成されている必要なIAMロールを提供する必要があります。

```bash wait=60
$ helm repo add netapp-trident https://netapp.github.io/trident-helm-chart
$ helm install trident-operator netapp-trident/trident-operator \
  --version 100.2410.0 --namespace trident --create-namespace --wait
```

次のようにしてインストールを確認できます：

```bash
$ kubectl get pods -n trident
NAME                                READY   STATUS    RESTARTS   AGE
trident-controller-b6b5899-kqdjh    6/6     Running   0          87s
trident-node-linux-9q4sj            2/2     Running   0          86s
trident-node-linux-bxg5s            2/2     Running   0          86s
trident-node-linux-z92x2            2/2     Running   0          86s
trident-operator-588c7c854d-t4c4x   1/1     Running   0          102s
```

FSx for NetApp ONTAPファイルシステムがストレージ仮想マシン（SVM）と、FSxマウントポイントへのNFSトラフィックを許可するインバウンドルールを含む必要なセキュリティグループとともにプロビジョニングされています。後で必要になるIDを取得しましょう：

```bash
$ export FSXN_ID=$(aws fsx describe-file-systems --output json | jq -r --arg cluster_name "${EKS_CLUSTER_NAME}-fsxn" '.FileSystems[] | select(.Tags[] | select(.Key=="Name" and .Value==$cluster_name)) | .FileSystemId')
$ echo $FSXN_ID
fs-0123456789abcdef0
```

FSx for NetApp ONTAP CSIドライバーは動的プロビジョニングと静的プロビジョニングの両方をサポートしています：

- **動的プロビジョニング**：ドライバーは既存のFSx for NetApp ONTAPファイルシステム上にボリュームを作成します。これには、StorageClassパラメータで指定する必要がある既存のAWS FSx for NetApp ONTAPファイルシステムが必要です。
- **静的プロビジョニング**：これも事前に作成されたAWS FSx for NetApp ONTAPファイルシステムが必要であり、ドライバーを使用してコンテナ内のボリュームとしてマウントできます。

次に、事前にプロビジョニングされたFSx for NetApp ONTAPファイルシステムを使用するように構成されたTridentBackendConfigオブジェクトを作成します。バックエンドを作成するために使用する`fsxn-backend-nas.yaml`ファイルを見てみましょう：

::yaml{file="manifests/modules/fundamentals/storage/fsxn/backend/fsxn-backend-nas.yaml" paths="spec.svm,spec.aws.fsxFilesystemID,spec.credentials.name"}

1. `svm`パラメータに`EKS_CLUSTER_NAME`環境変数を注入します - これはストレージ仮想マシン名です
2. `fsxFilesystemID`パラメータに`FSXN_ID`環境変数を注入します - これはCSIドライバーを接続するFSxNファイルシステムです
3. `credentials.name`パラメータに`FSXN_SECRET_ARN`環境変数を注入します - これはONTAP APIインターフェースに接続するための認証情報を含むAWS Secrets Managerに安全に保存されているシークレットのARNです

バックエンド構成を適用します：

```bash
$ kubectl kustomize ~/environment/eks-workshop/modules/fundamentals/storage/fsxn/backend \
  | envsubst | kubectl apply -f-
tridentbackendconfig.trident.netapp.io/backend-tbc-ontap-nas created
```

TridentBackendConfigが作成されたことを確認します：

```bash
$ kubectl get tbc -n trident
NAME                    BACKEND NAME    BACKEND UUID                           PHASE   STATUS
backend-tbc-ontap-nas   tbc-ontap-nas   bbae8686-25e4-4fca-a4c7-7ab664c7db9c   Bound   Success
```

次に、`fsxnstorageclass.yaml`ファイルを使用して[StorageClass](https://kubernetes.io/docs/concepts/storage/storage-classes/)オブジェクトを作成しましょう：

::yaml{file="manifests/modules/fundamentals/storage/fsxn/storageclass/fsxnstorageclass.yaml" paths="provisioner,parameters.backendType"}

1. Amazon FSx for NetApp ONTAP CSIプロビジョナーに`provisioner`パラメータを`csi.trident.netapp.io`に設定します
2. ONTAPボリュームへのアクセスにONTAP NASドライバーを使用することを示すために`backendType`を`ontap-nas`に設定します

StorageClassを適用します：

```bash
$ kubectl apply -f ~/environment/eks-workshop/modules/fundamentals/storage/fsxn/storageclass/fsxnstorageclass.yaml
storageclass.storage.k8s.io/fsxn-sc-nfs created
```

StorageClassを調べてみましょう。プロビジョナーとしてFSx for NetApp ONTAP CSIドライバーを使用し、ONTAP NASプロビジョニングモード用に構成されていることに注目してください：

```bash
$ kubectl get storageclass
NAME            PROVISIONER                RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
fsxn-sc-nfs     csi.trident.netapp.io      Delete          Immediate              true                   8m29s
$ kubectl describe sc fsxn-sc-nfs
Name:            fsxn-sc-nfs
IsDefaultClass:  No
Annotations:     kubectl.kubernetes.io/last-applied-configuration={"allowVolumeExpansion":true,"apiVersion":"storage.k8s.io/v1","kind":"StorageClass","metadata":{"annotations":{},"name":"fsxn-sc-nfs"},"parameters":{"backendType":"ontap-nas"},"provisioner":"csi.trident.netapp.io"}

Provisioner:           csi.trident.netapp.io
Parameters:            backendType=ontap-nas
AllowVolumeExpansion:  True
MountOptions:          <none>
ReclaimPolicy:         Delete
VolumeBindingMode:     Immediate
Events:                <none>
```

これでFSx for NetApp ONTAP StorageClassの理解とFSx for NetApp ONTAP CSIドライバーの仕組みが分かりました。次のステップに進む準備が整いました。次のステップでは、Kubernetes動的ボリュームプロビジョニングとPersistentVolumeを使用してFSx for NetApp ONTAP `StorageClass`を利用し、製品画像を保存するためにUIコンポーネントを変更します。
