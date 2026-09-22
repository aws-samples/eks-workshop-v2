---
title: ストレージ
sidebar_position: 20
tmdTranslationSourceHash: 51e6ff1065fd499e8e80ede104c36e16
---

[EKS上のストレージ](https://docs.aws.amazon.com/eks/latest/userguide/storage.html)では、EKSクラスターと2つのAWSストレージサービスを統合する方法の概要を説明します。

実装に入る前に、EKSと統合して利用する2つのAWSストレージサービスについて概要を説明します：

- [Amazon Elastic Block Store](https://aws.amazon.com/ebs/) (EC2のみサポート): EC2インスタンスとコンテナから専用のストレージボリュームへの直接アクセスを提供するブロックストレージサービスで、あらゆる規模のスループットとトランザクション集約型ワークロードの両方に対応するよう設計されています。
- [Amazon Elastic File System](https://aws.amazon.com/efs/) (FargateとEC2をサポート): 完全マネージド型でスケーラブル、かつ弾力性のあるファイルシステムで、ビッグデータ分析、Webサービング、コンテンツ管理、アプリケーション開発とテスト、メディアやエンターテイメントのワークフロー、データベースバックアップ、コンテナストレージに適しています。EFSはデータを複数のアベイラビリティゾーン(AZ)に冗長的に保存し、Kubernetesポッドが実行されているAZに関係なく低レイテンシーでのアクセスを提供します。
- [Amazon FSx for NetApp ONTAP](https://aws.amazon.com/fsx/netapp-ontap/) (EC2のみサポート): NetAppの人気のあるONTAPファイルシステム上に構築された完全マネージド型共有ストレージ。FSx for NetApp ONTAPはデータを複数のアベイラビリティゾーン(AZ)に冗長的に保存し、Kubernetesポッドが実行されているAZに関係なく低レイテンシーでのアクセスを提供します。
- [Amazon S3 Files](https://docs.aws.amazon.com/AmazonS3/latest/userguide/s3-files.html) (EC2、EKS、ECS、Lambdaをサポート): 任意のAWSコンピューティングリソースをAmazon S3内のデータと直接接続する共有ファイルシステム。完全なファイルシステムセマンティクスと低レイテンシーパフォーマンスを備えたファイルとしてすべてのS3データへの高速な直接アクセスを提供し、データがS3から移動することはありません。Amazon EFSテクノロジーを使用して構築されたS3 Filesは、ファイルシステムのパフォーマンスとシンプルさに加えて、S3のスケーラビリティ、耐久性、コスト効率を提供します。
- [Amazon FSx for Lustre](https://aws.amazon.com/fsx/lustre/) (EC2のみサポート): 機械学習、高性能コンピューティング、ビデオ処理、財務モデリング、電子設計自動化、分析などのワークロードに最適化された、完全マネージド型の高性能スケールアウトファイルシステム。FSx for Lustreを使用すると、S3データリポジトリにリンクされた高性能スケールアウトファイルシステムを迅速に作成し、S3オブジェクトをファイルとして透過的にアクセスできます。
- [Amazon FSx for OpenZFS](https://aws.amazon.com/fsx/openzfs/) (EC2のみサポート): 自己管理型データベース、業務用アプリケーション、コンテンツ管理システム、パッケージマネージャーなど、最低レイテンシーを必要とするワークロードに最適化された、完全マネージド型の高性能スケールアップファイルシステム。FSx for OpenZFSを使用すると、高可用性で高性能なスケールアップファイルシステムを迅速に作成でき、AWSのすべてのファイルサービスの中で最低レイテンシーと最低のGB単位のストレージ価格を実現します。

また、[Kubernetesのストレージ](https://kubernetes.io/docs/concepts/storage/)に関するいくつかの概念についても理解しておくことが非常に重要です：

- [ボリューム](https://kubernetes.io/docs/concepts/storage/volumes/): コンテナ内のディスク上のファイルは一時的なもので、コンテナで実行される重要なアプリケーションにはいくつかの問題が生じます。一つの問題は、コンテナがクラッシュした場合のファイルの損失です。kubeletはコンテナを再起動しますが、クリーンな状態で再起動します。二つ目の問題は、Podで一緒に実行されているコンテナ間でファイルを共有する際に発生します。Kubernetesのボリューム抽象化はこれらの問題を解決します。Podに関する知識が推奨されます。
- [エフェメラルボリューム](https://kubernetes.io/docs/concepts/storage/ephemeral-volumes/)はこれらのユースケースのために設計されています。ボリュームはPodのライフタイムに従い、Podと共に作成および削除されるため、永続的なボリュームが利用可能な場所に制限されることなく、Podを停止して再起動することができます。
- [Persistent Volumes (PV)](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)は、管理者が提供したか、Storage Classesを使用して動的にプロビジョニングされたクラスター内のストレージの一部です。これはノードがクラスターリソースであるのと同様に、クラスターのリソースです。PVはVolumesのようなボリュームプラグインですが、PVを使用する個々のPodとは独立したライフサイクルを持ちます。このAPIオブジェクトは、NFSやiSCSI、あるいはクラウドプロバイダー固有のストレージシステムなど、ストレージの実装の詳細を捉えます。
- [Persistent Volume Claim (PVC)](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)はユーザーによるストレージの要求です。これはPodに似ています。PodはノードリソースをConsume、PVCはPVリソースをConsumeします。Podは特定のレベルのリソース（CPUとメモリ）を要求できます。要求は特定のサイズとアクセスモードを要求できます（例えば、ReadWriteOnce、ReadOnlyMany、ReadWriteManyでマウント可能）。[アクセスモード](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#access-modes)を参照してください。
- [Storage Classes](https://kubernetes.io/docs/concepts/storage/storage-classes/)は、管理者が提供する「クラス」のストレージを記述する方法を提供します。異なるクラスはサービス品質レベル、バックアップポリシー、またはクラスター管理者によって決定される任意のポリシーに対応している場合があります。Kubernetes自体はクラスが何を表すかについて意見を持ちません。この概念は他のストレージシステムでは「プロファイル」と呼ばれることもあります。
- [Dynamic Volume Provisioning](https://kubernetes.io/docs/concepts/storage/dynamic-provisioning/)により、ストレージボリュームをオンデマンドで作成することができます。動的プロビジョニングがなければ、クラスター管理者は新しいストレージボリュームを作成するためにクラウドやストレージプロバイダーに手動で呼び出しを行い、それらをKubernetesで表現するためにPersistentVolumeオブジェクトを作成する必要があります。動的プロビジョニング機能は、クラスター管理者がストレージを事前にプロビジョニングする必要性を排除します。代わりに、ユーザーが要求した時に自動的にストレージをプロビジョニングします。

次のステップでは、まずAmazon EBSボリュームを統合して、Kubernetes上のStatefulSetオブジェクトを利用してカタログマイクロサービスからMySQLデータベースによって消費されるようにします。
その後、コンポーネントマイクロサービスのファイルシステムをAmazon EFS共有ファイルシステムを使用するように統合し、スケーラビリティ、レジリエンス、およびマイクロサービスのファイルに対するより多くのコントロールを提供します。

