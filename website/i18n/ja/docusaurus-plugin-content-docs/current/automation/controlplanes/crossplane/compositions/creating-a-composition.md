---
title: "コンポジションの作成"
sidebar_position: 10
kiteTranslationSourceHash: d0dc5064bac3a088b26405f948aa7024
---

`CompositeResourceDefinition`（XRD）は、コンポジットリソース（XR）のタイプとスキーマを定義します。これはCrossplaneに対して、望ましいXRとそのフィールドについて通知します。XRDはCustomResourceDefinition（CRD）に似ていますが、より規範的な構造を持っています。XRDを作成する主なステップは、OpenAPI ["構造的スキーマ"](https://kubernetes.io/docs/tasks/extend-kubernetes/custom-resources/custom-resource-definitions/)を指定することです。

まず、アプリケーションチームのメンバーが各自の名前空間でDynamoDBテーブルを作成できるようにする定義を提供しましょう。この例では、ユーザーは**名前**、**キー属性**、および**インデックス名**フィールドのみを指定する必要があります。

```file
manifests/modules/automation/controlplanes/crossplane/compositions/composition/definition.yaml
```

コンポジションは、コンポジットリソースが作成されたときにCrossplaneが取るべきアクションについて通知します。各コンポジションは、XRと1つ以上のマネージドリソースのセットの間にリンクを確立します。XRが作成、更新、または削除されると、関連するマネージドリソースも対応して作成、更新、または削除されます。

次のコンポジションは、マネージドリソース`Table`をプロビジョニングします：

```file
manifests/modules/automation/controlplanes/crossplane/compositions/composition/table.yaml
```

この設定をEKSクラスターに適用してみましょう：

```bash
$ kubectl apply -k ~/environment/eks-workshop/modules/automation/controlplanes/crossplane/compositions/composition
compositeresourcedefinition.apiextensions.crossplane.io/xdynamodbtables.awsblueprints.io created
composition.apiextensions.crossplane.io/table.dynamodb.awsblueprints.io created
```

これらのリソースを配置することで、DynamoDBテーブルを作成するためのCrossplaneコンポジションの設定が完了しました。この抽象化により、アプリケーション開発者は、基盤となるAWS固有の詳細を理解することなく、標準化されたDynamoDBテーブルをプロビジョニングできるようになりました。

