---
title: "コンポジションの作成"
sidebar_position: 10
tmdTranslationSourceHash: 641c30bbbdebb13b80074aaf46243eb8
---

`CompositeResourceDefinition`（XRD）は、コンポジットリソース（XR）のタイプとスキーマを定義します。これはCrossplaneに対して、望ましいXRとそのフィールドについて通知します。XRDはCustomResourceDefinition（CRD）に似ていますが、より規範的な構造を持っています。XRDを作成する主なステップは、OpenAPI ["構造的スキーマ"](https://kubernetes.io/docs/tasks/extend-kubernetes/custom-resources/custom-resource-definitions/)を指定することです。

まず、アプリケーションチームのメンバーが各自の名前空間でDynamoDBテーブルを作成できるようにする定義を提供しましょう。この例では、ユーザーは**名前**、**キー属性**、および**インデックス名**フィールドのみを指定する必要があります。

<details>
  <summary>XRDマニフェスト全体を表示</summary>

::yaml{file="manifests/modules/automation/controlplanes/crossplane/compositions/composition/definition.yaml"}

</details>

XRDマニフェストからDynamoDB固有の設定を確認してみましょう。

DynamoDBテーブル名の指定が必要なセクションは以下の通りです：

::yaml{file="manifests/modules/automation/controlplanes/crossplane/compositions/composition/definition.yaml" zoomPath="spec.versions.0.schema.openAPIV3Schema.properties.spec.properties.resourceConfig.properties.name.type" zoomBefore="9"}

このセクションはDynamoDBテーブルのキー属性の仕様を提供します：

::yaml{file="manifests/modules/automation/controlplanes/crossplane/compositions/composition/definition.yaml" zoomPath="spec.versions.0.schema.openAPIV3Schema.properties.spec.properties.dynamoConfig.properties.rangeKey" zoomBefore="20"}

これはグローバルセカンダリインデックスの仕様に関するセクションです：

::yaml{file="manifests/modules/automation/controlplanes/crossplane/compositions/composition/definition.yaml" zoomPath="spec.versions.0.schema.openAPIV3Schema.properties.spec.properties.dynamoConfig.properties.globalSecondaryIndex.type" zoomBefore="23"}

これはローカルセカンダリインデックスの仕様に関するセクションです：

::yaml{file="manifests/modules/automation/controlplanes/crossplane/compositions/composition/definition.yaml" zoomPath="spec.versions.0.schema.openAPIV3Schema.properties.spec.properties.dynamoConfig.properties.localSecondaryIndex.type" zoomBefore="19"}

コンポジションは、コンポジットリソースが作成されたときにCrossplaneが取るべきアクションについて通知します。各コンポジションは、XRと1つ以上のマネージドリソースのセットの間にリンクを確立します。XRが作成、更新、または削除されると、関連するマネージドリソースも対応して作成、更新、または削除されます。

<details>
  <summary>マネージドリソース`Table`をプロビジョニングするコンポジションを表示：</summary>

::yaml{file="manifests/modules/automation/controlplanes/crossplane/compositions/composition/table.yaml"}

</details>

これをいくつかのパートに分けて確認すると理解しやすくなります。

このセクションは、XRの`spec.name`フィールドをマネージドリソースのexternal-nameアノテーションにマッピングします。Crossplaneはこれを使用してAWSでの実際のDynamoDBテーブル名を設定します。

::yaml{file="manifests/modules/automation/controlplanes/crossplane/compositions/composition/table.yaml" zoomPath="spec.patchSets.0.patches.1.toFieldPath" zoomBefore="2"}

これはXRからすべての属性定義をマネージドDynamoDBリソースに転送し、Crossplaneが適切なデータ型でテーブルスキーマを作成できるようにします。

::yaml{file="manifests/modules/automation/controlplanes/crossplane/compositions/composition/table.yaml" zoomPath="spec.resources.0.patches.1.policy.mergeOptions" zoomBefore="4"}

これはXRからの最初の属性をDynamoDBテーブルのプライマリキー構造のパーティションキー（ハッシュキー）としてマッピングします。

::yaml{file="manifests/modules/automation/controlplanes/crossplane/compositions/composition/table.yaml" zoomPath="spec.resources.0.patches.3.toFieldPath" zoomBefore="2"}

これはXR仕様からGSI名をマネージドリソースに転送し、CrossplaneがDynamoDBテーブルに名前付きのグローバルセカンダリインデックスを作成できるようにします。

::yaml{file="manifests/modules/automation/controlplanes/crossplane/compositions/composition/table.yaml" zoomPath="spec.resources.0.patches.8.toFieldPath" zoomBefore="2"}

これはXRからLSI設定をマネージドリソースにマッピングし、Crossplaneが指定された名前と属性でローカルセカンダリインデックスをプロビジョニングできるようにします。

::yaml{file="manifests/modules/automation/controlplanes/crossplane/compositions/composition/table.yaml" zoomPath="spec.resources.0.patches.11.toFieldPath" zoomBefore="2"}


この設定をEKSクラスターに適用してみましょう：

```bash
$ kubectl apply -k ~/environment/eks-workshop/modules/automation/controlplanes/crossplane/compositions/composition
compositeresourcedefinition.apiextensions.crossplane.io/xdynamodbtables.awsblueprints.io created
composition.apiextensions.crossplane.io/table.dynamodb.awsblueprints.io created
```

これらのリソースを配置することで、DynamoDBテーブルを作成するためのCrossplaneコンポジションの設定が完了しました。この抽象化により、アプリケーション開発者は、基盤となるAWS固有の詳細を理解することなく、標準化されたDynamoDBテーブルをプロビジョニングできるようになりました。
