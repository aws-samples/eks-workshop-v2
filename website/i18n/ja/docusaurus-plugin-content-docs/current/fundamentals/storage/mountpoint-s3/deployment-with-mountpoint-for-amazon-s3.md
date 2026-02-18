---
title: S3による永続的オブジェクトストレージ
sidebar_position: 30
tmdTranslationSourceHash: a2905c137570577f1a4417aa32e22e51
---

前のステップでは、イメージオブジェクト用のステージングディレクトリを作成し、画像アセットをダウンロードしてS3バケットにアップロードすることで環境を準備しました。また、Mountpoint for Amazon S3 CSIドライバーをインストールして設定しました。ここでは、Mountpoint for Amazon S3 CSIドライバーが提供するPersistent Volume（PV）を使用するようにPodを接続することで、Amazon S3によって**水平スケーリング**と**永続ストレージ**を備えた画像ホストアプリケーションを作成するという目標を完成させます。

まず、[Persistent Volume](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)を作成し、デプロイメント内の`ui`コンテナがこのボリュームをマウントするように変更しましょう。

最初に、`s3pvclaim.yaml`ファイルを調べて、そのパラメータと設定を理解しましょう：

::yaml{file="manifests/modules/fundamentals/storage/s3/deployment/s3pvclaim.yaml" paths="spec.accessModes,spec.mountOptions,spec.csi.volumeAttributes.bucketName"}

1. `ReadWriteMany`：同じS3バケットを複数のPodに読み書き用としてマウントすることを許可します
2. `allow-delete`：マウントされたバケットからオブジェクトを削除することをユーザーに許可します  
   `allow-other`：所有者以外のユーザーがマウントされたバケットにアクセスすることを許可します  
   `uid=`：マウントされたバケット内のファイル/ディレクトリのユーザーID（UID）を設定します  
   `gid=`：マウントされたバケット内のファイル/ディレクトリのグループID（GID）を設定します  
   `region= $AWS_REGION`：S3バケットのリージョンを設定します
3. `bucketName`はS3バケット名を指定します

```kustomization
modules/fundamentals/storage/s3/deployment/deployment.yaml
Deployment/ui
```

それでは、この設定を適用してアプリケーションを再デプロイしましょう：

```bash hook=s3-deployment
$ kubectl kustomize ~/environment/eks-workshop/modules/fundamentals/storage/s3/deployment \
  | envsubst | kubectl apply -f-
namespace/ui unchanged
serviceaccount/ui unchanged
configmap/ui unchanged
service/ui unchanged
persistentvolume/s3-pv created
persistentvolumeclaim/s3-claim created
deployment.apps/ui configured
```

デプロイメントの進行状況を監視しましょう：

```bash
$ kubectl rollout status --timeout=180s deployment/ui -n ui
deployment "ui" successfully rolled out
```

ボリュームマウントを確認し、新しい`/mountpoint-s3`マウントポイントに注目しましょう：

```bash
$ kubectl get deployment -n ui -o yaml | yq '.items[].spec.template.spec.containers[].volumeMounts'
- mountPath: /mountpoint-s3
  name: mountpoint-s3
- mountPath: /tmp
  name: tmp-volume
```

次に、新しく作成されたPersistentVolumeを調べましょう：

```bash
$ kubectl get pv
NAME    CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM             STORAGECLASS   VOLUMEATTRIBUTESCLASS   REASON   AGE
s3-pv   1Gi        RWX            Retain           Bound    ui/s3-claim                      <unset>                          2m31s
```

PersistentVolumeClaimの詳細を確認しましょう：

```bash
$ kubectl describe pvc -n ui
Name:          s3-claim
Namespace:     ui
StorageClass:
Status:        Bound
Volume:        s3-pv
Labels:        <none>
Annotations:   pv.kubernetes.io/bind-completed: yes
Finalizers:    [kubernetes.io/pvc-protection]
Capacity:      1Gi
Access Modes:  RWX
VolumeMode:    Filesystem
Used By:       ui-9fbbbcd6f-c74vv
               ui-9fbbbcd6f-vb9jz
Events:        <none>
```

実行中のPodを確認しましょう：

```bash
$ kubectl get pods -n ui
NAME                  READY   STATUS    RESTARTS   AGE
ui-9fbbbcd6f-c74vv    1/1     Running   0          2m36s
ui-9fbbbcd6f-vb9jz    1/1     Running   0          2m38s
```

それでは、Mountpoint for Amazon S3 CSIドライバーを使用した最終的なデプロイメント設定を調べましょう：

```bash
$ kubectl describe deployment -n ui
Name:                   ui
Namespace:              ui
[...]
  Containers:
   ui:
    Image:      public.ecr.aws/aws-containers/retail-store-sample-ui:1.2.1
    Port:       8080/TCP
    Host Port:  0/TCP
    Limits:
      memory:  128Mi
    Requests:
      cpu:     128m
      memory:  128Mi
    [...]
    Mounts:
      /mountpoint-s3 from mountpoint-s3 (rw)
      /tmp from tmp-volume (rw)
  Volumes:
   mountpoint-s3:
    Type:       PersistentVolumeClaim (a reference to a PersistentVolumeClaim in the same namespace)
    ClaimName:  s3-claim
    ReadOnly:   false
   tmp-volume:
    Type:          EmptyDir (a temporary directory that shares a pod's lifetime)
    Medium:        Memory
    SizeLimit:     <unset>
[...]
```

ここで、共有ストレージ機能をデモンストレーションしましょう。まず、UIコンポーネントのPodの1つを通じて`/mountpoint-s3`内の現在のファイルをリストアップします：

```bash hook=sample-images
$ export POD_1=$(kubectl -n ui get pods -o jsonpath='{.items[0].metadata.name}')
$ kubectl exec --stdin $POD_1 -n ui -- bash -c 'ls /mountpoint-s3/'
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

このリストが先ほどS3バケットにアップロードした画像と一致していることがわかります。次に、`placeholder.jpg`という新しい画像を生成し、同じPodを通じてS3バケットに追加しましょう：

```bash
$ kubectl exec --stdin $POD_1 -n ui -- bash -c 'curl -sS -o /mountpoint-s3/placeholder.jpg https://placehold.co/600x400/jpg?text=EKS+Workshop\\nPlaceholder'
```

ストレージレイヤーの永続性と共有を確認するために、2番目のUIPodを使用して、作成したファイルを確認しましょう：

```bash
$ export POD_2=$(kubectl -n ui get pods -o jsonpath='{.items[1].metadata.name}')
$ kubectl exec --stdin $POD_2 -n ui -- bash -c 'ls /mountpoint-s3/'
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

最後に、S3バケット内の存在を確認しましょう：

```bash
$ aws s3 ls $BUCKET_NAME
2025-07-09 14:43:36     102950 1ca35e86-4b4c-4124-b6b5-076ba4134d0d.jpg
2025-07-09 14:43:36     118546 4f18544b-70a5-4352-8e19-0d070f46745d.jpg
2025-07-09 14:43:36     147820 631a3db5-ac07-492c-a994-8cd56923c112.jpg
2025-07-09 14:43:36     100117 79bce3f3-935f-4912-8c62-0d2f3e059405.jpg
2025-07-09 14:43:36     106911 8757729a-c518-4356-8694-9e795a9b3237.jpg
2025-07-09 14:43:36     113010 87e89b11-d319-446d-b9be-50adcca5224a.jpg
2025-07-09 14:43:36     171045 a1258cd2-176c-4507-ade6-746dab5ad625.jpg
2025-07-09 14:43:36     170438 cc789f85-1476-452a-8100-9e74502198e0.jpg
2025-07-09 14:43:36      97592 d27cf49f-b689-4a75-a249-d373e0330bb5.jpg
2025-07-09 14:43:36     169246 d3104128-1d14-4465-99d3-8ab9267c687b.jpg
2025-07-09 14:43:36     151884 d4edfedb-dbe9-4dd9-aae8-009489394955.jpg
2025-07-09 14:43:36     134344 d77f9ae6-e9a8-4a3e-86bd-b72af75cbc49.jpg
2025-07-09 15:10:27      10024 placeholder.jpg         <----------------
```

これで画像がUI経由で利用可能であることを確認できます：

```bash hook=placeholder
$ LB_HOSTNAME=$(kubectl -n ui get service ui-nlb -o jsonpath='{.status.loadBalancer.ingress[*].hostname}{"\n"}')
$ echo "http://$LB_HOSTNAME/assets/img/products/placeholder.jpg"
http://k8s-ui-uinlb-647e781087-6717c5049aa96bd9.elb.us-west-2.amazonaws.com/assets/img/products/placeholder.jpg
```

ブラウザでURLにアクセスしてください：

<Browser url="http://k8s-ui-uinlb-647e781087-6717c5049aa96b...">
<img src={require('@site/static/docs/fundamentals/storage/mountpoint-s3/placeholder.jpg').default}/>
</Browser>

これで、Mountpoint for Amazon S3をEKSで実行されるワークロードの永続的な共有ストレージとして使用する方法を正常に実証しました。
