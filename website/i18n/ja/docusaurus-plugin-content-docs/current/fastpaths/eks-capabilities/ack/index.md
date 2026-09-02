---
title: "ACK で AWS リソースをプロビジョニングする"
sidebar_position: 10
tmdTranslationSourceHash: "7a3ccda226e1ebe26e62b441f6532868"
---

::required-time{estimatedLabExecutionTimeMinutes="10"}

デフォルトでは、サンプルアプリケーションの `carts` コンポーネントは、`carts-dynamodb` という Pod として実行されている [DynamoDB local](https://docs.aws.amazon.com/ja_jp/amazondynamodb/latest/developerguide/DynamoDBLocal.html) インスタンスにデータを保存します。これは開発には便利ですが、テストや本番環境では、チームがデータベースの運用ではなくアプリケーションに集中できるように、通常は実際の Amazon DynamoDB テーブルが必要です。このラボでは、[AWS Controllers for Kubernetes (ACK)](https://aws-controllers-k8s.github.io/community/) を使用して Kubernetes から実際の DynamoDB テーブルをプロビジョニングし、その後 `carts` Deployment をそれに向けるように設定します。

Helm チャートを使用してクラスターにコントローラーをインストールすることで、ACK を自分で実行できます。これは[セルフマネージド ACK ラボ](/docs/automation/controlplanes/ack)で示されています。その場合、スケーリング、パッチ適用、アップグレード、各コントローラーが必要とする IAM の配線など、それらの運用も所有することになります。代わりに、このラボでは **ACK EKS capability** を使用します。コントローラーはクラスターとは別の AWS 所有のインフラストラクチャで実行され、AWS がそれらのスケーリング、パッチ適用、アップグレードを処理します。`ack-system` namespace はなく、ノード上にコントローラー Deployment もなく、`helm install ack-dynamodb-controller` ステップもありません。必要な AWS リソースを宣言すると、マネージド capability がそれを調整します。

:::info
Amazon EKS Capabilities は、ACK などのプラットフォームコンポーネントの運用を AWS にオフロードするため、プラットフォームインフラストラクチャの保守ではなく、アプリケーションのデプロイに集中できます。詳細については、[Amazon EKS Capabilities のアナウンス](https://aws.amazon.com/about-aws/whats-new/2025/11/amazon-eks-capabilities/)をご覧ください。
:::

:::tip 事前に設定されていること

- **ACK EKS マネージド capability** がクラスターで有効になっており、DynamoDB コントローラーが選択されています。capability は、`${EKS_CLUSTER_AUTO_NAME}-carts-fastpath` という名前の単一の DynamoDB テーブルにスコープされた IAM Capability Role を引き受けます。
- `carts` ServiceAccount 用の **IAM role** が事前にプロビジョニングされており（`${EKS_CLUSTER_AUTO_NAME}-carts-dynamo`）、アプリケーション Pod が [EKS Pod Identity](https://docs.aws.amazon.com/ja_jp/eks/latest/userguide/pod-identities.html) を介してテーブルの読み書きができるようになっています。
- ベースの retail アプリケーションが実行されており、`carts` はクラスター内の `carts-dynamodb` Pod を指しています。

:::

このラボでは、以下を行います：

1. ACK capability が `ACTIVE` であり、DynamoDB Custom Resource Definition (CRD) がクラスターに存在することを確認します。
2. Kubernetes `Table` リソースを適用して DynamoDB テーブルをプロビジョニングします。
3. ConfigMap と ServiceAccount を更新して、`carts` Deployment をクラスター内の DynamoDB Pod から新しい AWS マネージドテーブルに移行します。

## capability の確認

何かをプロビジョニングする前に、capability が `ACTIVE` であることを確認します。直接検査します：

```bash
$ aws eks describe-capability \
  --cluster-name $EKS_CLUSTER_AUTO_NAME \
  --capability-name $EKS_CAP_ACK_CAPABILITY \
  --query 'capability.status' --output text
ACTIVE
```

capability は `CREATING → ACTIVE` を経て遷移します。ステータスが `ACTIVE` 以外の場合は、しばらく待ってからコマンドを再実行してください。capability がまだ初期化中の可能性があります。

次に、DynamoDB コントローラーの CRD がクラスターに登録されていることを確認します：

```bash
$ kubectl get crd tables.dynamodb.services.k8s.aws \
  -o jsonpath='{.spec.names.kind}{"\n"}'
Table
```

```bash
$ kubectl api-resources --api-group=dynamodb.services.k8s.aws
NAME             SHORTNAMES   APIVERSION                              NAMESPACED   KIND
backups                       dynamodb.services.k8s.aws/v1alpha1      true         Backup
globaltables                  dynamodb.services.k8s.aws/v1alpha1      true         GlobalTable
tables                        dynamodb.services.k8s.aws/v1alpha1      true         Table
```

マネージド capability と一貫して、`ack-system` namespace はなく、ワーカーノード上にコントローラー Pod もありません。クラスター内に表示されるのは、capability が登録した CRD のみで、これに対して適用できます。capability が `ACTIVE` で CRD が配置されているため、Kubernetes から DynamoDB テーブルをプロビジョニングする準備ができました。

