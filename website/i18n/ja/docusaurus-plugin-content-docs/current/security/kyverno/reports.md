---
title: "レポートと監査"
sidebar_position: 74
tmdTranslationSourceHash: db98a354c23b018a8031ee4bd6e8843d
---

Kyvernoには、Kubernetes Policy Working Groupによって定義されたオープンフォーマットを使用する[ポリシーレポート](https://kyverno.io/docs/policy-reports/)ツールが含まれています。これらのレポートはクラスター内にカスタムリソースとしてデプロイされます。Kyvernoは、クラスター内で_CREATE_、_UPDATE_、_DELETE_などのアドミッションアクションが実行されると、これらのレポートを生成します。また、既存のリソースに対してポリシーを検証するバックグラウンドスキャンの結果としてもレポートが生成されます。

このワークショップを通じて、私たちは特定のルールを持ついくつかのポリシーを作成しました。リソースがポリシー定義に従って1つ以上のルールに一致し、それらのいずれかに違反すると、違反ごとにレポートにエントリが作成されます。同じリソースが複数のルールに一致して違反する場合、複数のエントリが作成される可能性があります。リソースが削除されると、そのエントリもレポートから削除されます。つまり、Kyvernoレポートは常にクラスターの現在の状態を表し、履歴情報は記録しません。

前述のように、Kyvernoには2種類の`validationFailureAction`があります：

1. `Audit`モード：リソースの作成を許可し、そのアクションをポリシーレポートに記録します。
2. `Enforce`モード：リソースの作成を拒否しますが、ポリシーレポートにエントリを追加しません。

例えば、`Audit`モードのポリシーに、すべてのDeploymentがpodテンプレートに`CostCenter`ラベルを設定することを要求する単一のルールがあり、そのラベルなしでDeploymentが作成された場合、Kyvernoはそのデploymentの作成を許可しますが、ルール違反のためポリシーレポートに`FAIL`結果として記録します。同じポリシーが`Enforce`モードで構成されている場合、KyvernoはDeploymentの作成を即座にブロックし、これはポリシーレポートにエントリを生成しません。ただし、ルールに準拠してDeploymentが作成された場合、レポートには`PASS`と報告されます。ブロックされたアクションは、アクションが要求されたネームスペースのKubernetesイベントで確認できます。

これまでのワークショップで作成したポリシーに対するクラスターのコンプライアンス状態を確認するため、生成されたポリシーレポートを見てみましょう。

```bash hook=reports
$ kubectl get policyreports -A
NAMESPACE     NAME                                   KIND         NAME                            PASS   FAIL   WARN   ERROR   SKIP   AGE
carts         50358693-2468-4b73-8873-c6239b90876c   Deployment   carts-dynamodb                  1      2      0      0       0      23m
carts         b0356ab5-e6a5-4326-a931-0e8d1a9f7f94   Deployment   carts                           3      0      0      0       1      23m
catalog       d6c40501-8f34-4398-97a6-27ab1050ef93   Deployment   catalog                         2      1      0      0       0      23m
checkout      3f896219-057e-40c0-bf99-c6ad4a57350b   Deployment   checkout                        2      1      0      0       0      23m
checkout      4df6b9d4-b87f-4a83-bbc3-985227280d2a   Deployment   checkout-redis                  2      1      0      0       0      23m
default       b71aba03-a65c-4ee2-baa1-0fc35b3a68ab   Deployment   nginx-public                    3      1      0      0       0      94s
default       f9802e1a-d2ee-4ee6-a9e2-c6d6f9fc7dab   Deployment   nginx-ecr                       4      0      0      0       0      14s
kube-system   ad06d729-02ec-4423-a534-fed4f1291516   Deployment   metrics-server                  1      2      0      0       0      23m
kube-system   de7f93d3-b4e5-42db-99c0-21b41559f9e3   Deployment   coredns                         1      2      0      0       0      23m
kyverno       1cfa691f-f809-4d5e-95d1-0a2367a834b0   Deployment   kyverno-reports-controller      1      2      0      0       0      23m
kyverno       94f688ff-b3de-400d-b7b5-6a17ccfe0dbd   Deployment   kyverno-admission-controller    1      2      0      0       0      23m
kyverno       adbaf20a-359b-4828-9a38-b0a30bd54d84   Deployment   kyverno-cleanup-controller      1      2      0      0       0      23m
kyverno       dd887a98-1d6f-48f6-a114-ab49eccdaa38   Deployment   kyverno-background-controller   1      2      0      0       0      23m
orders        40ed7842-7592-48b3-8998-eff2b16a898f   Deployment   orders                          2      1      0      0       0      23m
ui            590ae540-0bcc-4caa-8154-f7907fb31ff1   Deployment   ui                              3      0      0      0       0      23m
```

> 注：出力は異なる場合があります。レポートはすべてのネームスペースにあるDeploymentに対して生成されます。

Kyverno 1.13以降では、ポリシーレポートはポリシー単位ではなくリソース単位でスコープされます。各レポートはリソースのUIDによって命名され、そのリソースを評価したすべてのポリシーにわたって集約されたpass/failカウントが表示されます。ポリシーがDeploymentをターゲットにしているため、レポートはDeploymentリソースにスコープされています。レポートが`PASS`、`FAIL`、`WARN`、`ERROR`、`SKIP`を使用してリソースのステータスを表示していることがわかります。

前述のように、ブロックされたアクションはネームスペースのイベントに記録されます。以下のコマンドでそれらを調べてみましょう：

```bash
$ kubectl get events | grep block
9m11s       Warning   PolicyViolation     clusterpolicy/baseline-policy             Deployment default/privileged-deploy: [baseline] fail (blocked); Validation rule 'baseline' failed. It violates PodSecurity "baseline:latest": (Forbidden reason: privileged, field error list: [spec.template.spec.containers[0].securityContext.privileged is forbidden, forbidden values found: true])
18m         Warning   PolicyViolation     clusterpolicy/require-labels              Deployment ui/ui: [check-team] fail (blocked); validation error: Label 'CostCenter' is required on the Deployment pod template. rule check-team failed at path /spec/template/metadata/labels/CostCenter/
2m8s        Warning   PolicyViolation     clusterpolicy/restrict-image-registries   Deployment default/nginx-blocked: [validate-registries] fail (blocked); validation error: Unknown Image registry. rule validate-registries failed at path /spec/template/spec/containers/0/image/
```

> 注：出力は異なる場合があります。

各イベントは、このラボの前半でのポリシー違反に対応しています：
- `baseline-policy`は、`privileged: true`を追加するためにパッチを適用したときに`privileged-deploy` Deploymentをブロックしました
- `require-labels`は、podテンプレートに`CostCenter`ラベルがなかったため、`ui` Deploymentのrollout restartをブロックしました
- `restrict-image-registries`は、画像が信頼されていないレジストリから来ていたため、`nginx-blocked`をブロックしました

これらのイベントは、クラスター全体での強制アクションのリアルタイム監査証跡を提供します。

次に、ラボで使用した`default`ネームスペースのポリシーレポートを詳しく見てみましょう：

```bash
$ kubectl get policyreports
NAME                                   KIND         NAME           PASS   FAIL   WARN   ERROR   SKIP   AGE
b71aba03-a65c-4ee2-baa1-0fc35b3a68ab   Deployment   nginx-public   3      1      0      0       0      3m39s
f9802e1a-d2ee-4ee6-a9e2-c6d6f9fc7dab   Deployment   nginx-ecr      4      0      0      0       0      2m19s
```

`nginx-public` Deploymentには1つの`FAIL`があり、`nginx-ecr` Deploymentにはすべてpassがあることに注目してください。これは、すべてのClusterPolicyが`Enforce`モードで作成されたためです。ブロックされたリソースは報告されず、アドミット後にバックグラウンドスキャナーによって評価されたリソースのみが報告されます。公開されている画像を使用して実行したままにしておいた`nginx-public` Deploymentは、`restrict-image-registries`ポリシーに違反する唯一の残りのリソースです。

`nginx-public` Deploymentの違反をより詳細に調査するには、そのレポートを記述します。レポートはUIDによって命名されるため、`kubectl get policyreports`を使用して`nginx-public` Deploymentのレポート名を見つけ、それを記述します：

```bash
$ kubectl describe policyreport $(kubectl get policyreports -o json | jq -r '.items[] | select(.scope.name=="nginx-public") | .metadata.name')
Name:         a9b8c7d6-e5f4-3210-fedc-ba9876543210
Namespace:    default
Labels:       app.kubernetes.io/managed-by=kyverno
Annotations:  <none>
API Version:  wgpolicyk8s.io/v1alpha2
Kind:         PolicyReport
Scope:
  API Version:  apps/v1
  Kind:         Deployment
  Name:         nginx-public
  Namespace:    default
Results:
  Message:  validation error: Unknown Image registry. rule validate-registries failed at path /spec/template/spec/containers/0/image/
  Policy:   restrict-image-registries
  Result:   fail
  Rule:     validate-registries
  Scored:   true
  Source:   kyverno
  ...
Summary:
  Error:  0
  Fail:   1
  Pass:   3
  Skip:   0
  Warn:   0
Events:   <none>
```

レポートは、`nginx-public` Deploymentの`restrict-image-registries`に対する`fail`結果と検証エラーメッセージを示しています。`nginx-ecr` Deploymentには、すべてpassを持つ独自の個別のレポートがあります。このような方法でレポートを監視することは管理者にとって負担となる可能性があります。Kyvernoは[Policy reporter](https://kyverno.github.io/policy-reporter/core/targets/#policy-reporter-ui)のためのGUIベースのツールもサポートしていますが、これはこのワークショップの範囲外です。

このラボでは、KyvernoでKubernetes PSA/PSS構成を強化する方法を学びました。Pod Security Standards（PSS）とこれらの標準のKubernetesツリー内実装であるPod Security Admission（PSA）は、ポッドセキュリティを管理するための優れた基盤を提供します。Kubernetes Pod Security Policies（PSP）から切り替えるユーザーの大半は、PSA/PSS機能を使用して成功するはずです。

Kyvernoは、Kubernetesツリー内のポッドセキュリティ実装を活用し、いくつかの役立つ拡張機能を提供することで、PSA/PSSによって作成されたユーザーエクスペリエンスを向上させます。ポッドセキュリティラベルの適切な使用を管理するためにKyvernoを使用できます。さらに、新しいKyverno `validate.podSecurity`ルールを使用して、追加の柔軟性と強化されたユーザーエクスペリエンスでポッドセキュリティ標準を簡単に管理できます。そして、Kyverno CLIを使用すると、クラスターの上流でポリシー評価を自動化することができます。
