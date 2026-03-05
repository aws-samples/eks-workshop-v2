---
title: "シンプルなポリシーの作成"
sidebar_position: 71
tmdTranslationSourceHash: 5082eba1f15e9129c8ebc5336dd53c3d
---

Kyvernoには2種類のポリシーリソースがあります：クラスター全体のリソースに使用される**ClusterPolicy**と、名前空間付きリソースに使用される**Policy**です。Kyvernoポリシーの理解を深めるために、まずはDeploymentに対するラベル要件から始めましょう。

以下は、Podテンプレートに`CostCenter`ラベルを持たないDeploymentをブロックする`ClusterPolicy`のサンプルです：

::yaml{file="manifests/modules/security/kyverno/simple-policy/require-labels-policy.yaml" paths="spec.validationFailureAction,spec.rules,spec.rules.0.match,spec.rules.0.validate,spec.rules.0.validate.allowExistingViolations,spec.rules.0.validate.message,spec.rules.0.validate.pattern"}

1. `spec.validationFailureAction`は、検証されるリソースを許可して報告する（`Audit`）か、ブロックする（`Enforce`）かをKyvernoに指示します。デフォルトは`Audit`ですが、この例では`Enforce`に設定されています
2. `rules`セクションには、検証する1つ以上のルールが含まれています
3. `match`ステートメントはチェックの範囲を設定します。この場合、すべての`Deployment`リソースが対象になります
4. `validate`ステートメントは、定義された内容を肯定的にチェックしようとします。このステートメントがリクエストされたリソースと比較して真の場合、許可されます。偽の場合は、ブロックされます
5. `allowExistingViolations: false`は、既に違反しているDeploymentへの更新もブロックされることを保証します。デフォルトでは、Kyvernoはポリシーが適用される前に存在していた非準拠リソースへの更新を許可し、ワークロードの中断を回避します。これを`false`に設定することで、このギャップを閉じ、すべてのアドミッションリクエストに対してポリシーを厳密に適用します
6. `message`は、このルールが検証に失敗した場合にユーザーに表示されるメッセージです
7. `pattern`オブジェクトは、リソースでチェックされるパターンを定義します。この場合、Deployment spec内のPodテンプレートラベルで`spec.template.metadata.labels`に`CostCenter`があるかをチェックします

次のコマンドを使用してポリシーを作成します：

```bash
$ kubectl apply -f ~/environment/eks-workshop/modules/security/kyverno/simple-policy/require-labels-policy.yaml

clusterpolicy.kyverno.io/require-labels created
```

次に、`ui`のDeploymentを確認し、Podテンプレートのラベルを見てください：

```bash
$ kubectl -n ui get deployment ui -o jsonpath='{.spec.template.metadata.labels}' | jq
{
  "app.kubernetes.io/component": "service",
  "app.kubernetes.io/created-by": "eks-workshop",
  "app.kubernetes.io/instance": "ui",
  "app.kubernetes.io/name": "ui"
}
```

Podテンプレートには必要な`CostCenter`ラベルが欠けています。では、`ui`のDeploymentの強制的なロールアウトを試みてみましょう：

```bash hook=labels-blocked expectError=true
$ kubectl -n ui rollout restart deployment/ui
error: failed to patch: admission webhook "validate.kyverno.svc-fail" denied the request:

resource Deployment/ui/ui was blocked due to the following policies

require-labels:
  check-team: 'validation error: Label ''CostCenter'' is required on the Deployment
    pod template. rule check-team failed at path /spec/template/metadata/labels/CostCenter/'
```

ロールアウトは、require-labels Kyvernoポリシーによりアドミッションウェブフックがリクエストを拒否したため、失敗しました。

次に、以下のKustomizationパッチを使用して、`ui`のDeploymentに必要なラベル`CostCenter`を追加します：

```kustomization
modules/security/kyverno/simple-policy/ui-labeled/deployment.yaml
Deployment/ui
```

```bash
$ kubectl apply -k ~/environment/eks-workshop/modules/security/kyverno/simple-policy/ui-labeled
namespace/ui unchanged
serviceaccount/ui unchanged
configmap/ui unchanged
service/ui unchanged
deployment.apps/ui configured
$ kubectl -n ui rollout status deployment/ui
deployment "ui" successfully rolled out
$ kubectl -n ui get deployment ui -o jsonpath='{.spec.template.metadata.labels}' | jq
{
  "CostCenter": "IT",
  "app.kubernetes.io/component": "service",
  "app.kubernetes.io/created-by": "eks-workshop",
  "app.kubernetes.io/instance": "ui",
  "app.kubernetes.io/name": "ui"
}
```

ポリシーが満たされ、ロールアウトが成功しました。

### ミューテーションルール

上記の例では、`validationFailureAction`で定義されたデフォルトの動作でバリデーションポリシーがどのように機能するかを確認しました。しかし、Kyvernoはポリシー内でミューテーションルールを管理するためにも使用でき、APIリクエストを変更して、Kubernetesリソースに指定された要件を満たしたり強制したりすることができます。リソースの変更はバリデーションの前に行われるため、バリデーションルールはミューテーションセクションによって実行された変更と矛盾しません。

以下はミューテーションルールを定義したポリシーのサンプルです：

::yaml{file="manifests/modules/security/kyverno/simple-policy/add-labels-mutation-policy.yaml" paths="spec.rules.0.match,spec.rules.0.mutate"}

1. `match.any.resources.kinds: [Deployment]`は、この`ClusterPolicy`をクラスター全体のすべてのDeploymentリソースに対象としています
2. `mutate`はリソースの作成中に変更を行います（validateがブロック/許可するのに対して）。`patchStrategicMerge.spec.template.metadata.labels.CostCenter: IT`は、すべてのDeploymentのPodテンプレートラベルに自動的に`CostCenter: IT`を追加します

以下のコマンドを使用して上記のポリシーを作成しましょう：

```bash
$ kubectl apply -f  ~/environment/eks-workshop/modules/security/kyverno/simple-policy/add-labels-mutation-policy.yaml

clusterpolicy.kyverno.io/add-labels created
```

ミューテーションウェブフックを検証するために、ラベルを明示的に追加せずに`carts`のDeploymentをロールアウトしてみましょう：

```bash
$ kubectl -n carts rollout restart deployment/carts
deployment.apps/carts restarted
$ kubectl -n carts rollout status deployment/carts
deployment "carts" successfully rolled out
```

ポリシー要件を満たすために`carts`のDeploymentのPodテンプレートに`CostCenter=IT`ラベルが自動的に追加されたことを検証します：

```bash
$ kubectl -n carts get deployment carts -o jsonpath='{.spec.template.metadata.labels}' | jq
{
  "CostCenter": "IT",
  "app.kubernetes.io/component": "service",
  "app.kubernetes.io/created-by": "eks-workshop",
  "app.kubernetes.io/instance": "carts",
  "app.kubernetes.io/name": "carts"
}
```

ラベルは`carts`のDeploymentのPodテンプレートに自動的に注入されました。Kyvernoポリシーで`patchStrategicMerge`および`patchesJson6902`パラメータを使用して、Amazon EKSクラスター内の既存のリソースを変更することも可能です。

これはKyvernoを使用してDeploymentを検証および変更するシンプルな例でした。今後のラボでは、Pod Security Standardsの適用やコンテナイメージレジストリの制限など、より高度なユースケースを探索します。

