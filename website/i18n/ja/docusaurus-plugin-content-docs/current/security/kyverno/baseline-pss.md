---
title: "Pod Security Standardsの強制"
sidebar_position: 72
tmdTranslationSourceHash: 6c54eef9a32b6a258bedfd070210529b
---

[Pod Security Standards (PSS)](../pod-security-standards/)セクションの導入で説明したように、事前定義されたポリシーレベルには**Privileged**、**Baseline**、**Restricted**の3つがあります。Restricted PSSの実装が推奨されますが、適切に構成されていないとアプリケーションレベルで意図しない動作を引き起こす可能性があります。まずは、コンテナがHostProcess、HostPath、HostPortsへのアクセスや、トラフィックスヌーピングの許可など、既知の特権昇格を防ぐBaselineポリシーを設定することをお勧めします。その後、これらの特権アクセスを制限または禁止するための個別のポリシーを設定できます。

Kyverno Baselineポリシーは、単一のポリシーの下で既知の特権昇格をすべて制限するのに役立ちます。また、最新の脆弱性を発見した場合に、ポリシーに組み込むための定期的なメンテナンスと更新も可能です。

特権コンテナはホストが実行できるほとんどすべてのアクションを実行でき、コンテナイメージのビルドと公開を可能にするためにCI/CDパイプラインでよく使用されます。現在は修正されている[CVE-2022-23648](https://github.com/containerd/containerd/security/advisories/GHSA-crp2-qrr5-8pq7)では、悪意のある攻撃者がControl Groupsの`release_agent`機能を悪用してコンテナホスト上で任意のコマンドを実行することにより、特権コンテナから脱出する可能性がありました。

このラボでは、EKSクラスタ上で特権コンテナを持つDeploymentを作成します。ポリシーが設定されていない場合、Deploymentは自由に作成でき、そのPodテンプレートにパッチを適用して特権アクセスを追加できます：

```bash hook=baseline-setup
$ kubectl create deployment privileged-deploy --image=public.ecr.aws/nginx/nginx
deployment.apps/privileged-deploy created
$ kubectl patch deployment privileged-deploy --type=json \
  -p='[{"op":"add","path":"/spec/template/spec/containers/0/securityContext","value":{"privileged":true}}]'
deployment.apps/privileged-deploy patched
$ kubectl delete deployment privileged-deploy
deployment.apps "privileged-deploy" deleted
```

`kubectl patch`コマンドはJSONパッチを使用して、Podテンプレートの最初のコンテナに`securityContext`を追加し、`privileged: true`を設定します。これにより、コンテナにはホストへのほぼ無制限のアクセスが許可されます。このような昇格された特権機能を防ぎ、これらの権限の不正使用を避けるために、KyvernoでBaselineポリシーを設定することをお勧めします。

Pod Security Standardsのbaselineプロファイルは、Podを保護するための最も基本的かつ重要なステップの集合です。Kyverno 1.8以降、単一のルールを通じてプロファイル全体をクラスタに割り当てることができます。Baselineプロファイルによってブロックされる特権の詳細については、[Kyvernoドキュメント](https://kyverno.io/policies/#:~:text=Baseline%20Pod%20Security%20Standards,cluster%20through%20a%20single%20rule)を参照してください。

::yaml{file="manifests/modules/security/kyverno/baseline-policy/baseline-policy.yaml" paths="spec.background,spec.validationFailureAction,spec.rules.0.match,spec.rules.0.validate"}

1. `background: true`は、新規リソースだけでなく既存のリソースにもポリシーを適用します
2. `validationFailureAction: Enforce`は、ポリシーに準拠していないDeploymentの作成または更新をブロックします
3. `match.any.resources.kinds: [Deployment]`は、クラスタ全体のすべてのDeploymentリソースにポリシーを適用します
4. `allowExistingViolations: false`は、既に違反しているDeploymentへの更新もブロックされることを保証します
5. `validate.podSecurity`は、`latest`標準バージョンの`baseline`レベルで、DeploymentのPodテンプレートに対してKubernetes Pod Security Standardsを強制します

それでは、Baselineポリシーを適用しましょう：

```bash
$ kubectl apply -f ~/environment/eks-workshop/modules/security/kyverno/baseline-policy/baseline-policy.yaml
clusterpolicy.kyverno.io/baseline-policy created
```

次に、特権コンテナを持つDeploymentを作成してみましょう。まずDeploymentを作成し、次にPodテンプレートに`privileged: true`を追加するためにパッチを適用します：

```bash
$ kubectl create deployment privileged-deploy --image=public.ecr.aws/nginx/nginx
deployment.apps/privileged-deploy created
```

次に、特権セキュリティコンテキストを追加するためにパッチを適用してみましょう：

```bash expectError=true hook=baseline-blocked
$ kubectl patch deployment privileged-deploy --type=json \
  -p='[{"op":"add","path":"/spec/template/spec/containers/0/securityContext","value":{"privileged":true}}]'
Error from server: admission webhook "validate.kyverno.svc-fail" denied the request:

resource Deployment/default/privileged-deploy was blocked due to the following policies

baseline-policy:
  baseline: 'Validation rule ''baseline'' failed. It violates PodSecurity "baseline:latest":
    (Forbidden reason: privileged, field error list: [spec.template.spec.containers[0].securityContext.privileged
    is forbidden, forbidden values found: true])'
```

ご覧の通り、Podテンプレートに`privileged: true`を追加するパッチは、クラスタに設定したBaselineポリシーに準拠していないため、ブロックされました。

Deploymentをクリーンアップします：

```bash
$ kubectl delete deployment privileged-deploy --ignore-not-found=true
deployment.apps "privileged-deploy" deleted
```

