---
title: 既存のアーキテクチャ
sidebar_position: 10
tmdTranslationSourceHash: dfa8c6b7f2ed9d6283e9acd68e447831
---

このセクションでは、シンプルな画像ホスティングの例を使用して、Kubernetes デプロイメントでストレージを処理する方法を探ります。サンプルストアアプリケーションの既存のデプロイメントから始めて、画像ホストとして機能するように変更します。UI コンポーネントはステートレスなマイクロサービスであり、**水平スケーリング**と Pod の**宣言的な状態管理**を可能にするため、デプロイメントを実演するのに最適な例です。

UI コンポーネントの役割の1つは、静的な製品画像を提供することです。現在、これらの画像はビルドプロセス中にコンテナにバンドルされています。しかし、このアプローチには重大な制限があります - コンテナがデプロイされた後に新しい画像を追加することができません。この制限に対処するために、[Amazon FSx for Lustre](https://docs.aws.amazon.com/fsx/latest/LustreGuide/what-is.html) と Kubernetes の [Persistent Volume](https://kubernetes.io/docs/concepts/storage/persistent-volumes/) を使用して共有ストレージ環境を作成するソリューションを実装します。これにより、複数の Web サーバーコンテナが需要に応じて動的にスケールしながらアセットを提供できるようになります。

現在の Deployment のボリューム設定を確認してみましょう:

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

[`Volumes`](https://kubernetes.io/docs/concepts/storage/volumes/#emptydir-configuration-example) セクションを見ると、Deployment は現在 [EmptyDir ボリュームタイプ](https://kubernetes.io/docs/concepts/storage/volumes/#emptydir)を使用しており、これは Pod のライフタイム中のみ存在します。つまり、Pod が終了すると、このボリュームに保存されたデータは永久に失われます。

しかし、UI コンポーネントの場合、製品画像は現在 Spring Boot を介して[静的 Web コンテンツ](https://spring.io/blog/2013/12/19/serving-static-web-content-with-spring-boot)として提供されているため、画像はファイルシステム上に存在していません。

