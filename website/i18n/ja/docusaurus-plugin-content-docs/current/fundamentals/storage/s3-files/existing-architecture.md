---
title: 既存のアーキテクチャ
sidebar_position: 10
tmdTranslationSourceHash: 568a6494017ef724381c812513e9bb24
---

このセクションでは、シンプルな画像ホスティングの例を使用して、Kubernetes Deployment におけるストレージの処理方法を探ります。サンプルストアアプリケーションの既存の Deployment から始めて、画像ホストとして機能するように変更します。UI コンポーネントはステートレスなマイクロサービスであり、**水平スケーリング**と **Pod の宣言的状態管理**を可能にするため、Deployment を実演するのに最適な例です。

UI コンポーネントの役割の1つは、静的な商品画像を提供することです。現在、これらの画像はビルドプロセス中にコンテナにバンドルされています。しかし、このアプローチには大きな制限があります。コンテナがデプロイされた後、新しい画像を追加できないのです。この制限に対処するために、[Amazon S3 Files](https://docs.aws.amazon.com/AmazonS3/latest/userguide/s3-files.html) と Kubernetes [Persistent Volume](https://kubernetes.io/docs/concepts/storage/persistent-volumes/) を使用して、共有ストレージ環境を作成するソリューションを実装します。これにより、複数の Web サーバーコンテナが需要に合わせて動的にスケーリングしながらアセットを提供できるようになります。

S3 Files は、Amazon S3 によってバックアップされた真の NFS ファイルシステムを提供するという点で、他のストレージオプションとは異なります。データは常に S3 に保持されますが、S3 Files は高性能ストレージレイヤーを介して低レイテンシのファイルアクセスを提供します。ファイルシステムを介して行われた変更は自動的に S3 バケットに同期され、バケットに直接行われた変更はファイルシステムに反映されます。

現在の Deployment のボリューム設定を見てみましょう:

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

[`Volumes`](https://kubernetes.io/docs/concepts/storage/volumes/#emptydir-configuration-example) セクションを見ると、Deployment が現在 [EmptyDir ボリュームタイプ](https://kubernetes.io/docs/concepts/storage/volumes/#emptydir)を使用していることがわかります。これは Pod のライフタイムの間だけ存在します。つまり、Pod が終了すると、このボリュームに保存されているデータは永久に失われます。

しかし、UI コンポーネントの場合、商品画像は現在 Spring Boot を介して[静的 Web コンテンツ](https://spring.io/blog/2013/12/19/serving-static-web-content-with-spring-boot)として提供されているため、画像はファイルシステム上には存在していません。

