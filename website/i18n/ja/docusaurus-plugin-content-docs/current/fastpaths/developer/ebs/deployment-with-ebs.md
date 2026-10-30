---
title: 永続的な EBS ボリュームの使用
sidebar_position: 20
tmdTranslationSourceHash: 9fe30f4fb4bd054c70c10fb30958babd
---

それでは、catalog MySQL データベースを更新して、永続的な EBS ストレージを使用するようにしましょう。EKS Auto Mode では、EBS CSI Driver がすでにインストールされ、AWS によって管理されています。

## StorageClass の作成

StorageClass は、EKS Auto Mode が EBS ボリュームをプロビジョニングする方法を定義します。EKS Auto Mode には EBS CSI Driver が含まれていますが、ストレージ機能を使用するには、`ebs.csi.eks.amazonaws.com` を参照する StorageClass を作成する必要があります。

::yaml{file="manifests/modules/fastpaths/developers/ebs/storageclass.yaml" paths="provisioner,parameters.type"}

1. `provisioner: ebs.csi.eks.amazonaws.com` - EKS Auto Mode の組み込み EBS CSI Driver を使用します
2. `type: gp3` - EBS ボリュームタイプを指定します

StorageClass を適用します:

```bash
$ kubectl apply -f ~/environment/eks-workshop/modules/fastpaths/developers/ebs/storageclass.yaml
```

## catalog MySQL データベースの更新

`volumeClaimTemplates` を含む多くの StatefulSet フィールドは変更できないため、新しいストレージ構成で catalog サービスを削除して再作成する必要があります。

まず、現在の catalog MySQL StatefulSet を削除します:

```bash wait=10
$ kubectl delete -n catalog statefulset catalog-mysql
```

次に、永続的ストレージを有効にして再作成します。更新された StatefulSet には `volumeClaimTemplates` セクションが含まれています:

::yaml{file="manifests/modules/fastpaths/developers/ebs/statefulset-mysql.yaml" paths="spec.volumeClaimTemplates.0.spec.storageClassName,spec.volumeClaimTemplates.0.spec.accessModes,spec.volumeClaimTemplates.0.spec.resources"}

1. `accessModes` は ReadWriteOnce を指定し、ボリュームが単一のノードによってマウントされることを許可します
2. `storageClassName` は動的プロビジョニングのために ebs-sc StorageClass を指定します
3. 30GB の EBS ボリュームをリクエストしています

構成を適用し、catalog Pod を再起動してデータベースの初期化を確実にします:

```bash timeout=180
$ kubectl apply -k ~/environment/eks-workshop/modules/fastpaths/developers/ebs
$ kubectl rollout restart deployment/catalog -n catalog # DB 構造をプッシュするために catalog を強制的に再起動
```

## PersistentVolumeClaim の確認

再作成された catalog MySQL StatefulSet には、関連する PersistentVolumeClaim があります。

```bash
$ kubectl describe statefulset -n catalog catalog-mysql
Name:               catalog-mysql
Namespace:          catalog
...
  Containers:
   mysql:
    Image:      public.ecr.aws/docker/library/mysql:8.0
    Port:       3306/TCP
    Mounts:
      /var/lib/mysql from data (rw)
Volume Claims:
  Name:          data
  StorageClass:  
  Labels:        <none>
  Annotations:   <none>
  Capacity:      30Gi
  Access Modes:  [ReadWriteOnce]
```

作成された Persistent Volume Claim (PVC) を確認します:

```bash
$ kubectl get pvc -n catalog
NAME                   STATUS   VOLUME          CAPACITY   ACCESS MODES   STORAGECLASS   AGE
data-catalog-mysql-0   Bound    pvc-abc123...   30Gi       RWO            ebs-sc         2m
```

PVC の詳細を調査します:

```bash
$ kubectl describe pvc -n catalog data-catalog-mysql-0
Name:          data-catalog-mysql-0
Namespace:     catalog
StorageClass:  ebs-sc
Status:        Bound
Volume:        pvc-abc123...
Annotations:   pv.kubernetes.io/bind-completed: yes
               pv.kubernetes.io/bound-by-controller: yes
               volume.beta.kubernetes.io/storage-provisioner: ebs.csi.aws.com
Capacity:      30Gi
Access Modes:  RWO
VolumeMode:    Filesystem
Used By:       catalog-mysql-0
```

PVC は Persistent Volume (PV) にバインドされ、**ebs.csi.aws.com** を使用して 30Gi の容量でプロビジョニングされています。

## PersistentVolume (PV) の調査

```bash
$ kubectl describe pv $(kubectl get pvc -n catalog data-catalog-mysql-0 -o jsonpath="{.spec.volumeName}")
Name:              pvc-abc123...
Annotations:       pv.kubernetes.io/provisioned-by: ebs.csi.aws.com
StorageClass:      ebs-sc
Status:            Bound
Claim:             catalog/data-catalog-mysql-0
Reclaim Policy:    Delete
Access Modes:      RWO
VolumeMode:        Filesystem
Capacity:          30Gi
Node Affinity:
  Required Terms:
    Term 0:        topology.kubernetes.io/zone in [us-west-2a]
Source:
    Type:       CSI (a Container Storage Interface (CSI) volume source)
    Driver:     ebs.csi.aws.com
    FSType:     ext4
    VolumeHandle: vol-0abc123...
    ReadOnly:   false
```

**VolumeHandle** は Amazon EBS Volume ID を参照します。**Node Affinity** は、Pod が EBS ボリュームと同じ Availability Zone にスケジュールされることを保証します。

## EBS ボリュームの確認

EBS Volume ID を取得します:

```bash
$ MYSQL_PV_NAME=$(kubectl get pvc -n catalog data-catalog-mysql-0 -o jsonpath="{.spec.volumeName}")
$ MYSQL_EBS_VOL_ID=$(kubectl get pv $MYSQL_PV_NAME -o jsonpath="{.spec.csi.volumeHandle}")
$ echo "EBS Volume ID: $MYSQL_EBS_VOL_ID"
```

EBS ボリュームの詳細を表示します:

```bash
$ aws ec2 describe-volumes --volume-ids $MYSQL_EBS_VOL_ID | jq .
```

このボリュームは暗号化が有効になっている gp3 ストレージを使用しています。

## データの永続性のテスト

Pod の再起動後もデータが永続化されることを確認しましょう。まず、Pod の準備ができるまで待ちます:

```bash timeout=420
$ kubectl wait --for=condition=Ready -n catalog pod/catalog-mysql-0 --timeout=360s
```

MySQL データディレクトリにテストファイルを作成します:

```bash
$ kubectl exec -n catalog catalog-mysql-0 -- bash -c "echo 123 > /var/lib/mysql/test.txt"
```

テストファイルが作成されたことを確認します:

```bash
$ kubectl exec -n catalog catalog-mysql-0 -- ls -larth /var/lib/mysql/ | grep -i test
-rw-r--r--. 1 root  root     4 Oct 11 00:39 test.txt
```

次に、障害をシミュレートするために Pod を削除します:

```bash
$ kubectl delete pod -n catalog catalog-mysql-0
```

StatefulSet コントローラーが自動的に Pod を再作成するのを待ちます:

```bash
$ kubectl wait --for=condition=Ready -n catalog pod/catalog-mysql-0 --timeout=120s
```

Pod の再起動後もテストファイルが存在することを確認します:

```bash
$ kubectl exec -n catalog catalog-mysql-0 -- cat /var/lib/mysql/test.txt
123
```

成功です！テストファイルは Pod の再起動後も永続化されました。これは、データが Pod のエフェメラルストレージではなく、EBS ボリュームに保存されているためです。Amazon EBS がデータを保存し、AWS のアベイラビリティーゾーン内で安全かつ利用可能な状態を維持しています。

## まとめ

このセクションでは、以下を実施しました:

- catalog MySQL データベースを更新して、永続的な EBS ストレージを使用するようにしました
- EBS ボリュームが正しく作成されたことを確認しました
- Pod の再起動後もデータが永続化されることをテストしました

EKS Auto Mode では、EBS CSI Driver が事前にインストールされ、管理されているため、ステートフルなワークロードの永続的なブロックストレージを簡単にプロビジョニングできます。

