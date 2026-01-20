---
title: "Storage"
sidebar_position: 40
kiteTranslationSourceHash: 93d12c43499d46c34c149ebaf65d1917
---

Kubernetes ストレージリソースを表示するには、<i>Resources</i> タブをクリックしてください。<i>Storage</i> セクションに進むと、次のようなクラスタの一部である Kubernetes API リソースタイプを表示できます：

- Persistent Volume Claims
- Persistent Volumes
- Storage Classes
- Volume Attachments
- CSI Drivers
- CSI Nodes

[ストレージ](../../../fundamentals/storage/) ワークショップモジュールでは、ステートフルワークロードのストレージを構成および使用する方法について詳しく説明しています。

[PersistentVolumeClaim](https://kubernetes.io/docs/concepts/storage/persistent-volumes/) (PVC) はユーザーによるストレージ要求です。このリソースは Pod に似ています。Pod はノードリソースを消費し、PVC は Persistent Volume (PV) リソースを消費します。Pod は特定レベルのリソース（CPU およびメモリ）を要求できます。クレームは特定のサイズとアクセスモード（例えば、ReadWriteOnce、ReadOnlyMany または ReadWriteMany としてマウント可能）を要求できます。詳細は [AccessModes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#access-modes) をご覧ください。

[PersistentVolume](https://kubernetes.io/docs/concepts/storage/persistent-volumes/) PersistentVolume (PV) は、管理者によってプロビジョニングされた、または [Storage Classes](https://kubernetes.io/docs/concepts/storage/storage-classes/) を使用して動的にプロビジョニングされたクラスタ内の設定済みストレージユニットです。これはノードがクラスターリソースであるのと同様に、クラスター内のリソースです。PV は Volume と同様のボリュームプラグインですが、PV を使用する個々の Pod とは独立したライフサイクルを持ちます。この API オブジェクトは、EBS、EFS、または他のサードパーティ PV プロバイダーであるかに関わらず、ストレージの実装の詳細を取得します。

[StorageClass](https://kubernetes.io/docs/concepts/storage/storage-classes/) は、管理者がクラスターで利用可能なストレージの「クラス」を記述するための方法を提供します。異なるクラスは、サービス品質レベル、バックアップポリシー、またはクラスター管理者が決定した任意のポリシーに対応する場合があります。

[VolumeAttachment](https://kubernetes.io/docs/reference/kubernetes-api/config-and-storage-resources/volume-attachment-v1/) は、指定されたボリュームを指定されたノードに接続または切断する意図を取得します。

[Container Storage Interface (CSI)](https://kubernetes.io/docs/concepts/storage/volumes/#csi) は、Kubernetes が任意のストレージシステムをコンテナワークロードに公開するための標準インターフェイスを定義します。
Container Storage Interface (CSI) ノードプラグインは、ディスクデバイスのスキャンやファイルシステムのマウントなど、さまざまな特権操作を実行する必要があります。これらの操作は各ホストオペレーティングシステムによって異なります。Linux ワーカーノードでは、コンテナ化された CSI ノードプラグインは通常、特権コンテナとしてデプロイされます。Windows ワーカーノードでは、コンテナ化された CSI ノードプラグインの特権操作は、各 Windows ノードに事前インストールする必要があるコミュニティ管理のスタンドアロンバイナリである [csi-proxy](https://github.com/kubernetes-csi/csi-proxy) を使用してサポートされています。

