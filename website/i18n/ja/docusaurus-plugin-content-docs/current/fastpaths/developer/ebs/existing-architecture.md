---
title: 現在のストレージ構成
sidebar_position: 10
tmdTranslationSourceHash: 1150974f534eebd6354989f4c6fe4eac
---

catalog MySQL データベースが現在どのようにデータを保存しているかを確認しましょう。catalog サービスはバックエンドデータベースとして MySQL を使用しており、その現在のストレージ構成を確認します。

まず、catalog MySQL データベースの StatefulSet を見てみましょう:

```bash
$ kubectl describe statefulset -n catalog catalog-mysql
Name:               catalog-mysql
Namespace:          catalog
[...]
  Containers:
   mysql:
    Image:      public.ecr.aws/docker/library/mysql:8.0
    Port:       3306/TCP
    Mounts:
      /var/lib/mysql from data (rw)
  Volumes:
   data:
    Type:       EmptyDir (a temporary directory that shares a pod's lifetime)
[...]
```

StatefulSet は現在、Pod のライフタイムの間だけ存在する [EmptyDir volume](https://kubernetes.io/docs/concepts/storage/volumes/#emptydir) を使用しています。これは次のことを意味します:

- Pod が終了すると、すべてのデータベースデータが永久に失われます
- データベースは各 Pod の再起動時に新しい状態で開始されます
- Pod のライフサイクルイベント全体でデータの永続性がありません

これは本番環境のデータベースには適していません。次のセクションでは、Amazon EBS を使用して永続ストレージを構成し、データベースデータが Pod の再起動や障害を乗り越えて存続するようにします。

