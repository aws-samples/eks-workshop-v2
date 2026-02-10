---
title: 既存のアーキテクチャ
sidebar_position: 10
tmdTranslationSourceHash: 20faf3f0be007f2779faaab56eac26bf
---

このセクションでは、シンプルな画像ホスティングの例を使用して、Kubernetesデプロイメントでのストレージの扱い方について探ります。サンプルストアアプリケーションの既存のデプロイメントから始め、それを画像ホストとして機能するように変更します。UIコンポーネントはステートレスなマイクロサービスであり、Podの**水平スケーリング**と**宣言的状態管理**を可能にするため、デプロイメントを実証する優れた例です。

UIコンポーネントの役割の1つは、静的な製品画像を提供することです。現在、これらの画像はビルドプロセス中にコンテナにバンドルされています。しかし、このアプローチには重要な制限があります - コンテナがデプロイされた後に新しい画像を追加できないことです。この制限に対処するために、[Amazon FSx for NetApp ONTAP](https://docs.aws.amazon.com/fsx/latest/ONTAPGuide/what-is-fsx-ontap.html)とKubernetesの[Persistent Volume](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)を使用して、共有ストレージ環境を作成する解決策を実装します。これにより、複数のWebサーバーコンテナが需要に合わせて動的にスケールしながらアセットを提供できるようになります。

現在のDeploymentのボリューム設定を調べてみましょう：

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

[`Volumes`](https://kubernetes.io/docs/concepts/storage/volumes/#emptydir-configuration-example)セクションを見ると、現在のDeploymentはPodの存続期間中のみ存在する[EmptyDirボリュームタイプ](https://kubernetes.io/docs/concepts/storage/volumes/#emptydir)を使用していることがわかります。つまり、Podが終了すると、このボリュームに保存されたデータは永久に失われます。

しかし、UIコンポーネントの場合、製品画像は現在Spring Bootを介して[静的ウェブコンテンツ](https://spring.io/blog/2013/12/19/serving-static-web-content-with-spring-boot)として提供されているため、画像はファイルシステム上に存在していません。
