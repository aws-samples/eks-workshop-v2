---
title: 既存のアーキテクチャ
sidebar_position: 10
kiteTranslationSourceHash: bb9c6a9032116da065c0e84f7583fc19
---

このセクションでは、簡単な画像ホスティングの例を使用して、Kubernetesデプロイメントでストレージを処理する方法を探ります。サンプルストアアプリケーションの既存のデプロイメントから始めて、それを画像ホストとして機能するように修正します。UIコンポーネントはステートレスなマイクロサービスであり、**水平スケーリング**とPodの**宣言的な状態管理**を可能にするため、デプロイメントを示すのに優れた例です。

UIコンポーネントの役割の1つは、静的な製品画像を提供することです。これらの画像はビルドプロセス中にコンテナにバンドルされています。しかし、このアプローチには制限があります - 新しい画像を追加することができません。この問題に対処するために、[Amazon S3](https://docs.aws.amazon.com/AmazonS3/latest/userguide/Welcome.html)とKubernetesの[Persistent Volume](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)を使用して共有ストレージ環境を作成するソリューションを実装します。これにより、複数のWebサーバーコンテナが需要に応じてスケーリングしながら、アセットを提供することができるようになります。

現在のデプロイメントのボリューム構成を調べてみましょう：

```bash
$ kubectl describe deployment -n ui
Name:                   ui
Namespace:              ui
[...]
  Containers:
   assets:
    Image:      public.ecr.aws/aws-containers/retail-store-sample-ui:1.2.1
    Port:       8080/TCP
    Host Port:  0/TCP
    Limits:
      memory:  1536Mi
    Requests:
      cpu:     250
      memory:  1536Mi
    [...]
    Mounts:
      /tmp from tmp-volume (rw)
  Volumes:
   tmp-volume:
    Type:          EmptyDir (a temporary directory that shares a pod's lifetime)
    Medium:        Memory
    SizeLimit:     <unset>
[...]
```

[`Volumes`](https://kubernetes.io/docs/concepts/storage/volumes/#emptydir-configuration-example)セクションを見ると、デプロイメントは現在、Podのライフタイム中のみ存在する[EmptyDirボリュームタイプ](https://kubernetes.io/docs/concepts/storage/volumes/#emptydir)を使用していることがわかります。

しかし、UIコンポーネントの場合、製品画像は現在Spring Bootを介して[静的Webコンテンツ](https://spring.io/blog/2013/12/19/serving-static-web-content-with-spring-boot)として提供されているため、画像はファイルシステム上にはありません。
