---
title: "Creating a Simple Policy"
sidebar_position: 71
tmdTranslationSourceHash: 74cb17b16ab41b8584daae33b69a8d71
---

Kyvernoには2種類のポリシーリソースがあります：クラスター全体のリソースに使用される**ClusterPolicy**と、名前空間付きリソースに使用される**Policy**です。Kyvernoポリシーの理解を深めるために、まずはシンプルなPodラベル要件から始めましょう。ご存知の通り、Kubernetesではラベルがクラスター内のリソースにタグ付けするために使用されます。

以下は、`CostCenter`ラベルを持たないPodの作成をブロックする`ClusterPolicy`のサンプルです：

::yaml{file="manifests/modules/security/kyverno/simple-policy/require-labels-policy.yaml" paths="spec.validationFailureAction,spec.rules,spec.rules.0.match,spec.rules.0.validate,spec.rules.0.validate.message,spec.rules.0.validate.pattern"}

1. `spec.validationFailureAction`は、検証に失敗したリソースを許可して報告する（`Audit`）か、ブロックする（`Enforce`）かをKyvernoに指示します。デフォルトは`Audit`ですが、この例では`Enforce`に設定されています
2. `rules`セクションには、検証する1つ以上のルールが含まれています
3. `match`ステートメントはチェックの範囲を設定します。この場合、すべてのPodリソースが対象になります
4. `validate`ステートメントは、定義された内容を肯定的にチェックしようとします。このステートメントがリクエストされたリソースと比較して真の場合、許可されます。偽の場合は、ブロックされます
5. `message`は、このルールが検証に失敗した場合にユーザーに表示されるメッセージです
6. `pattern`オブジェクトは、リソースでチェックされるパターンを定義します。この場合、`metadata.labels`内に`CostCenter`があるかをチェックします

次のコマンドを使用してポリシーを作成します：

```bash
$ kubectl apply -f ~/environment/eks-workshop/modules/security/kyverno/simple-policy/require-labels-policy.yaml

clusterpolicy.kyverno.io/require-labels created
```

次に、`ui`名前空間で実行されているPodを確認し、適用されているラベルを確認してください：

```bash
$ kubectl -n ui get pods --show-labels
NAME                  READY   STATUS    RESTARTS   AGE   LABELS
ui-67d8cf77cf-d4j47   1/1     Running   0          9m    app.kubernetes.io/component=service,app.kubernetes.io/created-by=eks-workshop,app.kubernetes.io/instance=ui,app.kubernetes.io/name=ui,pod-template-hash=67d8cf77cf
```

実行中のPodに必要なラベルがなく、Kyvernoがそれを終了しなかったことに注目してください。これは、Kyvernoが`AdmissionController`として機能し、クラスターに既に存在するリソースには干渉しないためです。

ただし、実行中のPodを削除すると、必要なラベルがないため再作成されることはありません。`ui`名前空間で実行中のPodを削除してみましょう：

```bash
$ kubectl -n ui delete pod --all
pod "ui-67d8cf77cf-d4j47" deleted
$ kubectl -n ui get pods
No resources found in ui namespace.
```

前述の通り、Podは再作成されませんでした。`ui`デプロイメントの強制的なロールアウトを試みてみましょう：

```bash expectError=true
$ kubectl -n ui rollout restart deployment/ui
error: failed to patch: admission webhook "validate.kyverno.svc-fail" denied the request:

resource Deployment/ui/ui was blocked due to the following policies

require-labels:
  autogen-check-team: 'validation error: Label ''CostCenter'' is required to deploy
    the Pod. rule autogen-check-team failed at path /spec/template/metadata/labels/CostCenter/'
```

ロールアウトは、`require-labels` Kyvernoポリシーによってリクエストが拒否されたため、失敗しました。

また、`ui`デプロイメントを記述したり、`ui`名前空間の`events`を表示したりしてこの`error`メッセージを確認することもできます：

```bash
$ kubectl -n ui describe deployment ui
...
Events:
  Type     Reason             Age                From                   Message
  ----     ------             ----               ----                   -------
  Warning  PolicyViolation    12m (x2 over 9m)   kyverno-scan           policy require-labels/autogen-check-team fail: validation error: Label 'CostCenter' is required to deploy the Pod. rule autogen-check-team failed at path /spec/template/metadata/labels/CostCenter/

$ kubectl -n ui get events | grep PolicyViolation
9m         Warning   PolicyViolation     pod/ui-67d8cf77cf-hvqcd    policy require-labels/check-team fail: validation error: Label 'CostCenter' is required to deploy the Pod. rule check-team failed at path /metadata/labels/CostCenter/
9m         Warning   PolicyViolation     replicaset/ui-67d8cf77cf   policy require-labels/autogen-check-team fail: validation error: Label 'CostCenter' is required to deploy the Pod. rule autogen-check-team failed at path /spec/template/metadata/labels/CostCenter/
9m         Warning   PolicyViolation     deployment/ui              policy require-labels/autogen-check-team fail: validation error: Label 'CostCenter' is required to deploy the Pod. rule autogen-check-team failed at path /spec/template/metadata/labels/CostCenter/
```

次に、以下のKustomizationパッチを使用して、`ui`デプロイメントに必要なラベル`CostCenter`を追加します：

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
$ kubectl -n ui get pods --show-labels
NAME                  READY   STATUS    RESTARTS   AGE   LABELS
ui-5498685db8-k57nk   1/1     Running   0          60s   CostCenter=IT,app.kubernetes.io/component=service,app.kubernetes.io/created-by=eks-workshop,app.kubernetes.io/instance=ui,app.kubernetes.io/name=ui,pod-template-hash=5498685db8
```

ご覧の通り、アドミッションウェブフックはポリシーを正常に検証し、正しいラベル`CostCenter=IT`でPodが作成されました！

### ミューテーションルールについて

上記の例では、`validationFailureAction`で定義されたデフォルトの動作でバリデーションポリシーがどのように機能するかを確認しました。しかし、Kyvernoはポリシー内でミューテーションルールを管理するためにも使用でき、APIリクエストを変更して、Kubernetesリソースに指定された要件を満たしたり強制したりすることができます。リソースの変更はバリデーションの前に行われるため、バリデーションルールはミューテーションセクションによって実行された変更と矛盾しません。

以下はミューテーションルールを定義したポリシーのサンプルです：

::yaml{file="manifests/modules/security/kyverno/simple-policy/add-labels-mutation-policy.yaml" paths="spec.rules.0.match,spec.rules.0.mutate"}

1. `match.any.resources.kinds: [Pod]`は、この`ClusterPolicy`をクラスター全体のすべてのPodリソースに対象としています
2. `mutate`はリソースの作成中に変更を行います（validateがブロック/許可するのに対して）。`patchStrategicMerge.metadata.labels.CostCenter: IT`は、すべてのPodに自動的に`CostCenter: IT`ラベルを追加します

以下のコマンドを使用して上記のポリシーを作成しましょう：

```bash
$ kubectl apply -f  ~/environment/eks-workshop/modules/security/kyverno/simple-policy/add-labels-mutation-policy.yaml

clusterpolicy.kyverno.io/add-labels created
```

ミューテーションウェブフックを検証するために、ラベルを明示的に追加せずに`carts`デプロイメントをロールアウトしてみましょう：

```bash
$ kubectl -n carts rollout restart deployment/carts
deployment.apps/carts restarted
$ kubectl -n carts rollout status deployment/carts
deployment "carts" successfully rolled out
```

デプロイメントにラベルが指定されていなくても、ポリシー要件を満たすためにPodに`CostCenter=IT`ラベルが自動的に追加され、Podの作成が成功したことを検証します：

```bash
$ kubectl -n carts get pods --show-labels
NAME                     READY   STATUS    RESTARTS   AGE   LABELS
carts-bb88b4789-kmk62   1/1     Running   0          25s   CostCenter=IT,app.kubernetes.io/component=service,app.kubernetes.io/created-by=eks-workshop,app.kubernetes.io/instance=carts,app.kubernetes.io/name=carts,pod-template-hash=bb88b4789
```

Kyvernoポリシーで`patchStrategicMerge`および`patchesJson6902`パラメータを使用して、Amazon EKSクラスター内の既存のリソースを変更することも可能です。

これはPodにラベルを付けるシンプルな例でした。これはさまざまなシナリオに適用できます。例えば、未知のレジストリからの画像の制限、ConfigMapsへのデータの追加、許容の設定など多岐にわたります。今後のラボでは、より高度なユースケースをいくつか探索します。
