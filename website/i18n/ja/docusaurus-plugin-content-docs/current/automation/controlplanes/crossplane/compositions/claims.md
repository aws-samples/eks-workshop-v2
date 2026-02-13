---
title: "クレーム"
sidebar_position: 20
tmdTranslationSourceHash: e2242d07ab73cb3b3449da39419dc89c
---

Crossplaneに新しいXRの詳細を設定した後、直接作成するか、クレームを使用することができます。通常、Crossplaneの構成を担当するチーム（多くの場合、プラットフォームチームまたはSREチーム）のみがXRを直接作成する権限を持っています。その他の人は、Composite Resource Claim（略してクレーム）と呼ばれる軽量のプロキシリソースを通じてXRを管理します。

このクレームにより、開発者はテーブルを作成するために**DynamoDBテーブル名、ハッシュキー、およびグローバルインデックス名**のデフォルトのみを指定する必要があります。これにより、プラットフォームチームやSREチームは、課金モード、デフォルトの読み書き容量、プロジェクションタイプ、コストやインフラ関連のタグなどの側面を標準化することができます。

::yaml{file="manifests/modules/automation/controlplanes/crossplane/compositions/claim/claim.yaml" paths="metadata.name,spec.dynamoConfig.attribute.0,spec.dynamoConfig.attribute.1,spec.dynamoConfig.globalSecondaryIndex"}

1. クラスター名環境変数をプレフィックスとして使用したDynamoDBテーブル名を指定します
2. `id`をプライマリキー属性として指定します
3. `customerId`をセカンダリー属性として指定します
4. `idx_global_customerId`をグローバルセカンダリインデックス名として指定します

まず、前の「マネージドリソース」セクションで作成したDynamoDBテーブルをクリーンアップしましょう：

```bash
$ kubectl delete tables.dynamodb.aws.upbound.io --all --ignore-not-found=true
$ kubectl wait --for=delete tables.dynamodb.aws.upbound.io --all --timeout=5m
```

次に、`Claim`を作成してテーブルを再作成できます：

```bash timeout=400
$ cat ~/environment/eks-workshop/modules/automation/controlplanes/crossplane/compositions/claim/claim.yaml \
  | envsubst | kubectl -n carts apply -f -
dynamodbtable.awsblueprints.io/eks-workshop-carts-crossplane created
$ kubectl wait dynamodbtables.awsblueprints.io ${EKS_CLUSTER_NAME}-carts-crossplane -n carts \
  --for=condition=Ready --timeout=5m
```

AWSマネージドサービスのプロビジョニングには時間がかかります。DynamoDBの場合、最大で2分かかることがあります。CrossplaneはKubernetesのCompositeおよびマネージドリソースの`SYNCED`フィールドに調整のステータスを報告します。

```bash
$ kubectl get table
NAME                                        READY   SYNCED   EXTERNAL-NAME                   AGE
eks-workshop-carts-crossplane-bt28w-lnb4r   True   True      eks-workshop-carts-crossplane   6s
```

では、このクレームを使用してDynamoDBテーブルがどのようにデプロイされるかを理解しましょう：

![Crossplane reconciler concept](/docs/automation/controlplanes/crossplane/ddb-claim-architecture.webp)

カートネームスペースにデプロイされたクレーム`DynamoDBTable`を照会すると、Composite Resource（XR）`XDynamoDBTable`を指し、作成することがわかります：

```bash
$ kubectl get DynamoDBTable -n carts -o yaml | grep "resourceRef:" -A 3

    resourceRef:
      apiVersion: awsblueprints.io/v1alpha1
      kind: XDynamoDBTable
      name: eks-workshop-carts-crossplane-bt28w
```

Composition `table.dynamodb.awsblueprints.io`は、Composite Resource Kind（XR-KIND）が`XDynamoDBTable`であることを示しています。このCompositionは、`XDynamoDBTable` XRを作成したときにCrossplaneが何をすべきかを指示します。各Compositionは、XRと1つ以上のマネージドリソースのセットの間にリンクを作成します。

```bash
$ kubectl get composition
NAME                              XR-KIND          XR-APIVERSION               AGE
table.dynamodb.awsblueprints.io   XDynamoDBTable   awsblueprints.io/v1alpha1   143m
```

任意のネームスペースに限定されていない`XDynamoDBTable` XRを照会すると、DynamoDBマネージドリソース`Table`を作成していることがわかります：

```bash
$ kubectl get XDynamoDBTable -o yaml | grep "resourceRefs:" -A 3

    resourceRefs:
    - apiVersion: dynamodb.aws.upbound.io/v1beta1
      kind: Table
      name: eks-workshop-carts-crossplane-bt28w-lnb4r
```
