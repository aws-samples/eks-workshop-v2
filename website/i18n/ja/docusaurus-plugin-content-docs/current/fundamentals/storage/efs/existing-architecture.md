---
title: 既存のアーキテクチャ
sidebar_position: 10
kiteTranslationSourceHash: e7fa8bb681353347169a9fd75e98b0ff
---

このセクションでは、シンプルな画像ホスティング例を使用して、Kubernetesデプロイメントでのストレージの取り扱い方法を探ります。サンプルストアアプリケーションの既存のデプロイメントから始め、それを画像ホストとして機能するように変更します。UIコンポーネントはステートレスなマイクロサービスであり、**水平スケーリング**とPodの**宣言的な状態管理**を可能にするため、デプロイメントのデモンストレーションに最適な例です。

UIコンポーネントの役割の1つは、静的な製品画像を提供することです。現在、これらの画像はビルドプロセス中にコンテナにバンドルされています。しかし、このアプローチには重大な制限があります - コンテナがデプロイされた後に新しい画像を追加することができません。この制限に対処するために、[Amazon Elastic File System](https://docs.aws.amazon.com/efs/latest/ug/whatisefs.html)とKubernetesの[Persistent Volume](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)を使用して、共有ストレージ環境を作成するソリューションを実装します。これにより、複数のWebサーバーコンテナが資産を提供しながら、需要に応じて動的にスケールすることが可能になります。

現在のDeploymentのボリューム構成を調べてみましょう：

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

[`Volumes`](https://kubernetes.io/docs/concepts/storage/volumes/#emptydir-configuration-example)セクションを見ると、現在のDeploymentがPodの存続期間中のみ存在する[EmptyDirボリュームタイプ](https://kubernetes.io/docs/concepts/storage/volumes/#emptydir)を使用していることがわかります。これは、Podが終了すると、このボリュームに保存されたデータが永久に失われることを意味します。

ただし、UIコンポーネントの場合、製品画像は現在[Spring Bootによる静的Webコンテンツ](https://spring.io/blog/2013/12/19/serving-static-web-content-with-spring-boot)として提供されているため、画像はファイルシステム上に存在していません。
