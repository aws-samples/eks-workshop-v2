---
title: "レポートと監査"
sidebar_position: 74
tmdTranslationSourceHash: 13483d5a9434039d172da677200da045
---

Kyvernoには、Kubernetes Policy Working Groupによって定義されたオープンフォーマットを使用する[ポリシーレポート](https://kyverno.io/docs/policy-reports/)ツールが含まれています。これらのレポートはクラスター内にカスタムリソースとしてデプロイされます。Kyvernoは、クラスター内で*CREATE*、_UPDATE_、*DELETE*などのアドミッションアクションが実行されると、これらのレポートを生成します。また、既存のリソースに対してポリシーを検証するバックグラウンドスキャンの結果としてもレポートが生成されます。

このワークショップを通じて、私たちは特定のルールを持ついくつかのポリシーを作成しました。リソースがポリシー定義に従って1つ以上のルールに一致し、それらのいずれかに違反すると、違反ごとにレポートにエントリが作成されます。同じリソースが複数のルールに一致して違反する場合、複数のエントリが作成される可能性があります。リソースが削除されると、そのエントリもレポートから削除されます。つまり、Kyvernoレポートは常にクラスターの現在の状態を表し、履歴情報は記録しません。

前述のように、Kyvernoには2種類の`validationFailureAction`があります：

1. `Audit`モード：リソースの作成を許可し、そのアクションをポリシーレポートに記録します。
2. `Enforce`モード：リソースの作成を拒否しますが、ポリシーレポートにエントリを追加しません。

例えば、`Audit`モードのポリシーに、すべてのリソースに`CostCenter`ラベルを設定する単一のルールがあり、そのラベルなしでPodが作成された場合、Kyvernoはそのポッドの作成を許可しますが、ルール違反のためポリシーレポートに`FAIL`結果として記録します。同じポリシーが`Enforce`モードで構成されている場合、Kyvernoはリソースの作成を即座にブロックし、これはポリシーレポートにエントリを生成しません。ただし、ルールに準拠してPodが作成された場合、レポートには`PASS`と報告されます。ブロックされたアクションは、アクションが要求されたネームスペースのKubernetesイベントで確認できます。

これまでのワークショップで作成したポリシーに対するクラスターのコンプライアンス状態を確認するため、生成されたポリシーレポートを見てみましょう。

```bash hook=reports
$ kubectl get policyreports -A

NAMESPACE     NAME                             PASS   FAIL   WARN   ERROR   SKIP   AGE
assets        cpol-baseline-policy             3      0      0      0       0      19m
assets        cpol-require-labels              0      3      0      0       0      27m
assets        cpol-restrict-image-registries   3      0      0      0       0      25m
carts         cpol-baseline-policy             6      0      0      0       0      19m
carts         cpol-require-labels              0      6      0      0       0      27m
carts         cpol-restrict-image-registries   3      3      0      0       0      25m
catalog       cpol-baseline-policy             5      0      0      0       0      19m
catalog       cpol-require-labels              0      5      0      0       0      27m
catalog       cpol-restrict-image-registries   5      0      0      0       0      25m
checkout      cpol-baseline-policy             6      0      0      0       0      19m
checkout      cpol-require-labels              0      6      0      0       0      27m
checkout      cpol-restrict-image-registries   6      0      0      0       0      25m
default       cpol-baseline-policy             2      0      0      0       0      19m
default       cpol-require-labels              2      0      0      0       0      13m
default       cpol-restrict-image-registries   1      1      0      0       0      13m
kube-system   cpol-baseline-policy             4      8      0      0       0      19m
kube-system   cpol-require-labels              0      12     0      0       0      27m
kube-system   cpol-restrict-image-registries   0      12     0      0       0      25m
kyverno       cpol-baseline-policy             24     0      0      0       0      19m
kyverno       cpol-require-labels              0      24     0      0       0      27m
kyverno       cpol-restrict-image-registries   0      24     0      0       0      25m
orders        cpol-baseline-policy             6      0      0      0       0      19m
orders        cpol-require-labels              0      6      0      0       0      27m
orders        cpol-restrict-image-registries   6      0      0      0       0      25m
ui            cpol-baseline-policy             3      0      0      0       0      19m
ui            cpol-require-labels              0      3      0      0       0      27m
ui            cpol-restrict-image-registries   3      0      0      0       0      25m
```

> 注：出力は異なる場合があります。

ClusterPoliciesを使用していたため、上記の出力では、リソースを検証するために作成した`default`ネームスペースだけでなく、すべてのネームスペースでレポートが生成されていることがわかります。レポートは`PASS`、`FAIL`、`WARN`、`ERROR`、`SKIP`を使用してオブジェクトのステータスを表示しています。

前述のように、ブロックされたアクションはネームスペースのイベントに記録されます。以下のコマンドでそれらを調べてみましょう：

```bash
$ kubectl get events | grep block
8m         Warning   PolicyViolation   clusterpolicy/restrict-image-registries   Pod default/nginx-public: [validate-registries] fail (blocked); validation error: Unknown Image registry. rule validate-registries failed at path /spec/containers/0/image/
3m         Warning   PolicyViolation   clusterpolicy/restrict-image-registries   Pod default/nginx-public: [validate-registries] fail (blocked); validation error: Unknown Image registry. rule validate-registries failed at path /spec/containers/0/image/
```

> 注：出力は異なる場合があります。

次に、ラボで使用した`default`ネームスペースのポリシーレポートを詳しく見てみましょう：

```bash
$ kubectl get policyreports
NAME                                           PASS   FAIL   WARN   ERROR   SKIP   AGE
default       cpol-baseline-policy             2      0      0      0       0      19m
default       cpol-require-labels              2      0      0      0       0      13m
default       cpol-restrict-image-registries   1      1      0      0       0      13m
```

`restrict-image-registries` ClusterPolicyに対して、1つの`FAIL`と1つの`PASS`レポートがあることに注目してください。これは、すべてのClusterPolicyが`Enforce`モードで作成されたためです。また、前述のように、ブロックされたリソースは報告されません。さらに、ポリシールールに違反する可能性のあった既存のリソースはすでに削除されています。

公開されている画像を使用して実行したままにしておいた`nginx` Podは、`restrict-image-registries`ポリシーに違反する唯一の残りのリソースであり、レポートに表示されています。

このポリシーの違反をより詳細に調査するには、特定のレポートを記述します。`restrict-image-registries` ClusterPolicyの検証結果を確認するために、`cpol-restrict-image-registries`レポートに対して`kubectl describe`コマンドを使用します：

```bash
$ kubectl describe policyreport cpol-restrict-image-registries
Name:         cpol-restrict-image-registries
Namespace:    default
Labels:       app.kubernetes.io/managed-by=kyverno
              cpol.kyverno.io/restrict-image-registries=607025
Annotations:  <none>
API Version:  wgpolicyk8s.io/v1alpha2
Kind:         PolicyReport
Metadata:
  Creation Timestamp:  2024-01-18T01:03:40Z
  Generation:          1
  Resource Version:    607320
  UID:                 7abb6c11-9610-4493-ab1e-df94360ce773
Results:
  Message:  validation error: Unknown Image registry. rule validate-registries failed at path /spec/containers/0/image/
  Policy:   restrict-image-registries
  Resources:
    API Version:  v1
    Kind:         Pod
    Name:         nginx
    Namespace:    default
    UID:          dd5e65a9-66b5-4192-89aa-a291d150807d
  Result:         fail
  Rule:           validate-registries
  Scored:         true
  Source:         kyverno
  Timestamp:
    Nanos:    0
    Seconds:  1705539793
  Message:    validation rule 'validate-registries' passed.
  Policy:     restrict-image-registries
  Resources:
    API Version:  v1
    Kind:         Pod
    Name:         nginx-ecr
    Namespace:    default
    UID:          e638aad7-7fff-4908-bbe8-581c371da6e3
  Result:         pass
  Rule:           validate-registries
  Scored:         true
  Source:         kyverno
  Timestamp:
    Nanos:    0
    Seconds:  1705539793
Summary:
  Error:  0
  Fail:   1
  Pass:   1
  Skip:   0
  Warn:   0
Events:   <none>
```

上記の出力は、`nginx` Podのポリシー検証が`fail`結果と検証エラーメッセージを受け取ったことを示しています。一方、`nginx-ecr`のポリシー検証は`pass`結果を受け取りました。このような方法でレポートを監視することは管理者にとって負担となる可能性があります。Kyvernoは[Policy reporter](https://kyverno.github.io/policy-reporter/core/targets/#policy-reporter-ui)のためのGUIベースのツールもサポートしていますが、これはこのワークショップの範囲外です。

このラボでは、KyvernoでKubernetes PSA/PSS構成を強化する方法を学びました。Pod Security Standards（PSS）とこれらの標準のKubernetesツリー内実装であるPod Security Admission（PSA）は、ポッドセキュリティを管理するための優れた基盤を提供します。Kubernetes Pod Security Policies（PSP）から切り替えるユーザーの大半は、PSA/PSS機能を使用して成功するはずです。

Kyvernoは、Kubernetesツリー内のポッドセキュリティ実装を活用し、いくつかの役立つ拡張機能を提供することで、PSA/PSSによって作成されたユーザーエクスペリエンスを向上させます。ポッドセキュリティラベルの適切な使用を管理するためにKyvernoを使用できます。さらに、新しいKyverno `validate.podSecurity`ルールを使用して、追加の柔軟性と強化されたユーザーエクスペリエンスでポッドセキュリティ標準を簡単に管理できます。そして、Kyverno CLIを使用すると、クラスターの上流でポリシー評価を自動化することができます。
