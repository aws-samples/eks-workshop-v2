---
title: S3 Filesを使用した静的プロビジョニング
sidebar_position: 30
tmdTranslationSourceHash: 293360447972abae5b305ada7ef2c4ee
---

S3 FilesのストレージクラスとS3 Filesが静的プロビジョニングを使用する理由を理解したので、事前に作成されたS3ファイルシステム用に[Persistent Volume](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)を静的にプロビジョニングし、UIコンポーネントをマウントするように変更しましょう。

S3ファイルシステムは、バージョニングが有効なS3バケットにリンクされた状態でプロビジョニングされています。ファイルシステムには、マウントターゲットと、ポート2049でNFSトラフィックを許可するインバウンドルールを含む必要なセキュリティグループが含まれています。静的`PersistentVolume`に必要なIDを取得しましょう:

```bash
$ export S3_FILES_ID=$(aws s3files list-file-systems \
    --query "fileSystems[?starts_with(bucket, 'arn:aws:s3:::${EKS_CLUSTER_NAME}-s3-files-')].fileSystemId | [0]" \
    --output text)
$ echo $S3_FILES_ID
fs-0123456789abcdef0
```

静的プロビジョニングでは、セットとして機能する3つのオブジェクトを定義します:

1. パラメータなしの`StorageClass`(`s3-files-sc`)で、ボリュームとクレームをバインドするためだけに使用されます
2. 既存のS3ファイルシステムを直接指し示す`PersistentVolume`(`s3-files-pv`)
3. その特定の`PersistentVolume`にバインドする`PersistentVolumeClaim`(`s3-files-claim`)

静的プロビジョニングの[StorageClass](https://kubernetes.io/docs/concepts/storage/storage-classes/)は、`PersistentVolume`と`PersistentVolumeClaim`の間のバインディングラベルとしてのみ機能します。意図的に**パラメータがない**ため、ドライバーがオンデマンドで何かをプロビジョニングしようとすることはありません:

::yaml{file="manifests/modules/fundamentals/storage/s3-files/pv/s3filesstorageclass.yaml" paths="provisioner"}

1. `provisioner`パラメータを`efs.csi.aws.com`に設定します - S3 FilesはEFS CSIドライバーを使用するため、EFSに使用されるものと同じプロビジョナーです
2. `parameters`がないことに注意してください: 動的プロビジョニングとは異なり、ドライバーにファイルシステムやアクセスポイントの作成を要求していません

では、`PersistentVolume`と`PersistentVolumeClaim`を見てみましょう:

::yaml{file="manifests/modules/fundamentals/storage/s3-files/pv/s3filespv.yaml" paths="spec.csi.driver,spec.csi.volumeHandle,spec.persistentVolumeReclaimPolicy"}

1. `csi.driver`は`efs.csi.aws.com`で、S3 Filesも提供するEFS CSIドライバーです
2. `volumeHandle`は、ファイルシステムIDの前に`s3files:`プレフィックスを使用します(例:`s3files:fs-0123456789abcdef0`)。このプレフィックスは、ドライバーにEFSファイルシステムではなくS3ファイルシステムをマウントするよう指示します。`$S3_FILES_ID`環境変数がここに注入されます。
3. 再利用ポリシーは`Retain`なので、クレームを削除しても基礎となるS3ファイルシステムやそのデータは削除されません

`PersistentVolumeClaim`は`volumeName: s3-files-pv`を設定しているため、動的プロビジョニングをトリガーするのではなく、定義したボリュームに正確にバインドされます。

kustomizationを適用し、`StorageClass`、`PersistentVolume`、`PersistentVolumeClaim`を作成します:

```bash
$ kubectl kustomize ~/environment/eks-workshop/modules/fundamentals/storage/s3-files/pv \
  | envsubst | kubectl apply -f-
storageclass.storage.k8s.io/s3-files-sc created
persistentvolume/s3-files-pv created
persistentvolumeclaim/s3-files-claim created
```

`PersistentVolume`は事前に作成されているため、クレームに即座にバインドされます:

```bash
$ kubectl get pv
NAME          CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                STORAGECLASS   REASON   AGE
s3-files-pv   5Gi        RWX            Retain           Bound    ui/s3-files-claim    s3-files-sc             10s
```

PersistentVolumeClaim(PVC)の詳細を確認してみましょう:

```bash
$ kubectl describe pvc s3-files-claim -n ui
Name:          s3-files-claim
Namespace:     ui
StorageClass:  s3-files-sc
Status:        Bound
Volume:        s3-files-pv
Labels:        <none>
Annotations:   pv.kubernetes.io/bind-completed: yes
Finalizers:    [kubernetes.io/pvc-protection]
Capacity:      5Gi
Access Modes:  RWX
VolumeMode:    Filesystem
Used By:       <none>
Events:        <none>
```

クレームが静的に定義した`s3-files-pv`ボリュームに`Bound`されていることに注目してください - 外部プロビジョナーが何かを作成する必要はありませんでした。

次に、S3 Files PVCを参照するようにUIコンポーネントを更新します:

```kustomization
modules/fundamentals/storage/s3-files/deployment/deployment.yaml
Deployment/ui
```

このパッチは、小さな`fix-permissions` initコンテナも追加します。`ui`コンテナは非rootユーザー`1000`として実行されますが、S3 Filesボリュームは`root`が所有した状態でマウントされます。S3 FilesはNFSベースのファイルシステムを使用するため、PodのfsGroup設定は、Amazon EBSのようなブロックストレージの場合のようにマウントされたボリュームの所有権を自動的に変更しません。initコンテナは`root`として実行され、`ui`コンテナが起動する前にマウントをユーザー`1000`に`chown`するため、アプリケーションが`/s3files`に書き込めるようになります。これがないと、このラボの後半での書き込みのような操作が権限エラーで失敗します。

次のコマンドでこれらの変更を適用します:

```bash hook=s3-files-deployment
$ kubectl apply -k ~/environment/eks-workshop/modules/fundamentals/storage/s3-files/deployment
namespace/ui unchanged
serviceaccount/ui unchanged
configmap/ui unchanged
service/ui unchanged
deployment.apps/ui configured
$ kubectl rollout status --timeout=130s deployment/ui -n ui
```

デプロイメントの`volumeMounts`を確認してみましょう。`s3filesvolume`という名前の新しいボリュームが`/s3files`にマウントされていることに注目してください:

```bash
$ kubectl get deployment -n ui \
  -o yaml | yq '.items[].spec.template.spec.containers[].volumeMounts'
- mountPath: /s3files
  name: s3filesvolume
- mountPath: /tmp
  name: tmp-volume
```

この時点で、S3ファイルシステムは正常にマウントされていますが、現在は空です:

```bash
$ POD_1=$(kubectl -n ui get pods -l app.kubernetes.io/instance=ui -o jsonpath='{.items[0].metadata.name}')
$ kubectl exec --stdin $POD_1 -n ui -- bash -c 'ls /s3files/'
```

[Kubernetes Job](https://kubernetes.io/docs/concepts/workloads/controllers/job/)を使用して、S3 Filesボリュームに画像を取り込みましょう:

```bash
$ export PVC_NAME="s3-files-claim"
$ cat ~/environment/eks-workshop/modules/fundamentals/storage/populate-images-job.yaml | envsubst | kubectl apply -f -
$ kubectl wait --for=condition=complete -n ui \
  job/populate-images --timeout=300s
```

次に、UIコンポーネントのPodの1つを通じて`/s3files`内の現在のファイルをリストすることで、共有ストレージ機能を実証しましょう:

```bash
$ POD_1=$(kubectl -n ui get pods -l app.kubernetes.io/instance=ui -o jsonpath='{.items[0].metadata.name}')
$ kubectl exec --stdin $POD_1 -n ui -- bash -c 'ls /s3files/'
1ca35e86-4b4c-4124-b6b5-076ba4134d0d.jpg
4f18544b-70a5-4352-8e19-0d070f46745d.jpg
631a3db5-ac07-492c-a994-8cd56923c112.jpg
79bce3f3-935f-4912-8c62-0d2f3e059405.jpg
8757729a-c518-4356-8694-9e795a9b3237.jpg
87e89b11-d319-446d-b9be-50adcca5224a.jpg
a1258cd2-176c-4507-ade6-746dab5ad625.jpg
cc789f85-1476-452a-8100-9e74502198e0.jpg
d27cf49f-b689-4a75-a249-d373e0330bb5.jpg
d3104128-1d14-4465-99d3-8ab9267c687b.jpg
d4edfedb-dbe9-4dd9-aae8-009489394955.jpg
d77f9ae6-e9a8-4a3e-86bd-b72af75cbc49.jpg
```

S3 FilesはファイルシステムとS3バケットの間でデータを自動的に同期するため、基礎となるS3バケットにも画像が存在することを確認できます:

```bash
$ export S3_FILES_BUCKET_NAME=$(aws s3api list-buckets \
    --query "Buckets[?starts_with(Name, '${EKS_CLUSTER_NAME}-s3-files-')].Name | [0]" --output text)
$ aws s3 ls $S3_FILES_BUCKET_NAME
                           PRE /
2025-07-09 14:43:36     102950 1ca35e86-4b4c-4124-b6b5-076ba4134d0d.jpg
2025-07-09 14:43:36     118546 4f18544b-70a5-4352-8e19-0d070f46745d.jpg
[...]
```

`PRE /`エントリは、S3 Filesがバケット内のファイルシステムのルートディレクトリを表現するために使用するゼロバイトのオブジェクトです - `fix-permissions` initコンテナがマウントルートに所有権を設定するときに作成されます。これは、S3 FilesがPOSIXファイルシステムをS3オブジェクトにマッピングする方法の通常の一部であり、エラーではなく、画像ファイルには影響しません。すべての画像ファイルは、バケットのトップレベルにそれと一緒に表示されます。

共有ストレージ機能をさらに実証するために、`placeholder.jpg`という新しい画像を作成し、最初のPodを通じてS3 Filesボリュームに追加しましょう:

```bash
$ POD_1=$(kubectl -n ui get pods -l app.kubernetes.io/instance=ui -o jsonpath='{.items[0].metadata.name}')
$ kubectl exec --stdin $POD_1 -n ui -- bash -c 'curl -sS -o /s3files/placeholder.jpg https://placehold.co/600x400/jpg?text=EKS+Workshop\\nPlaceholder'
```

次に、2番目のUI Podがこの新しく作成されたファイルにアクセスできることを確認し、S3 Filesストレージの共有性を実証します:

```bash hook=sample-images
$ POD_2=$(kubectl -n ui get pods -l app.kubernetes.io/instance=ui -o jsonpath='{.items[1].metadata.name}')
$ kubectl exec --stdin $POD_2 -n ui -- bash -c 'ls /s3files/'
1ca35e86-4b4c-4124-b6b5-076ba4134d0d.jpg
4f18544b-70a5-4352-8e19-0d070f46745d.jpg
631a3db5-ac07-492c-a994-8cd56923c112.jpg
79bce3f3-935f-4912-8c62-0d2f3e059405.jpg
8757729a-c518-4356-8694-9e795a9b3237.jpg
87e89b11-d319-446d-b9be-50adcca5224a.jpg
a1258cd2-176c-4507-ade6-746dab5ad625.jpg
cc789f85-1476-452a-8100-9e74502198e0.jpg
d27cf49f-b689-4a75-a249-d373e0330bb5.jpg
d3104128-1d14-4465-99d3-8ab9267c687b.jpg
d4edfedb-dbe9-4dd9-aae8-009489394955.jpg
d77f9ae6-e9a8-4a3e-86bd-b72af75cbc49.jpg
placeholder.jpg      <----------------
```

ご覧のとおり、最初のPodを通じてファイルを作成したにもかかわらず、両方のPodが同じ共有S3ファイルシステムにアクセスしているため、2番目のPodもすぐにアクセスできます。

S3 Filesは、この新しいファイルも基礎となるS3バケットに自動的に同期し、S3 APIを通じてもアクセスできるようにします。

最後に、UIサービスを通じて画像にアクセスできることを確認しましょう:

```bash hook=placeholder
$ LB_HOSTNAME=$(kubectl -n ui get service ui-nlb -o jsonpath='{.status.loadBalancer.ingress[*].hostname}{"\n"}')
$ echo "http://$LB_HOSTNAME/assets/img/products/placeholder.jpg"
http://k8s-ui-uinlb-647e781087-6717c5049aa96bd9.elb.us-west-2.amazonaws.com/assets/img/products/placeholder.jpg
```

ブラウザでURLにアクセスしてください:

<Browser url="http://k8s-ui-uinlb-647e781087-6717c5049aa96b...">
<img src={require('@site/static/docs/fundamentals/storage/s3-files/placeholder.jpg').default}/>
</Browser>

Amazon S3 Filesが、Amazon EKS上で実行されているワークロードに永続的な共有ストレージを提供する方法を実証しました。このソリューションは、ファイルシステムのシンプルさとパフォーマンスとAmazon S3のスケーラビリティと耐久性を組み合わせることで、複数のPodが同じストレージボリュームに同時に読み書きできるようにし、データをS3バケットと同期させたままにします。

