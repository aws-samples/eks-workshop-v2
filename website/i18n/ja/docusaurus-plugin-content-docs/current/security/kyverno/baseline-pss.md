---
title: "Pod Security Standardsの強制"
sidebar_position: 72
kiteTranslationSourceHash: c73e1c6640a88b0b608c828cae171b40
---

[Pod Security Standards (PSS)](../pod-security-standards/)セクションの導入で説明したように、事前定義されたポリシーレベルには**Privileged**、**Baseline**、**Restricted**の3つがあります。Restrictedなポリシーの実装が推奨されますが、適切に構成されていないとアプリケーションレベルで意図しない動作を引き起こす可能性があります。まずは、コンテナがHostProcess、HostPath、HostPortsへのアクセスや、トラフィックスヌーピングの許可など、既知の特権昇格を防ぐBaselineポリシーを設定することをお勧めします。その後、これらの特権アクセスを制限または禁止するための個別のポリシーを設定できます。

Kyverno Baselineポリシーは、単一のポリシーの下で既知の特権昇格をすべて制限するのに役立ちます。また、最新の脆弱性を発見した場合に、ポリシーに組み込むための定期的なメンテナンスと更新も可能です。

特権コンテナはホストが実行できるほとんどすべてのアクションを実行でき、コンテナイメージのビルドと公開を可能にするためにCI/CDパイプラインでよく使用されます。現在は修正されている[CVE-2022-23648](https://github.com/containerd/containerd/security/advisories/GHSA-crp2-qrr5-8pq7)では、悪意のある攻撃者がControl Groupsの`release_agent`機能を悪用してコンテナホスト上で任意のコマンドを実行することにより、特権コンテナから脱出する可能性がありました。

このラボでは、EKSクラスタ上で特権Podを実行してみましょう。以下のコマンドを実行してください：

```bash
$ kubectl run privileged-pod --image=nginx --restart=Never --privileged
pod/privileged-pod created
$ kubectl delete pod privileged-pod
pod "privileged-pod" deleted
```

このような昇格された特権機能を防ぎ、これらの権限の不正使用を避けるために、KyvernoでBaselineポリシーを設定することをお勧めします。

Pod Security Standardsのbaselineプロファイルは、Podを保護するための最も基本的かつ重要なステップの集合です。Kyverno 1.8以降、単一のルールを通じてプロファイル全体をクラスタに割り当てることができます。BaselineプロファイルによってブロックされるCOPrivilegesの詳細については、[Kyvernoドキュメント](https://kyverno.io/policies/#:~:text=Baseline%20Pod%20Security%20Standards,cluster%20through%20a%20single%20rule)を参照してください。

::yaml{file="manifests/modules/security/kyverno/baseline-policy/baseline-policy.yaml" paths="spec.background,spec.validationFailureAction,spec.rules.0.match,spec.rules.0.validate"}

1. `background: true`は、新規リソースだけでなく既存のリソースにもポリシーを適用します
2. `validationFailureAction: Enforce`は、ポリシーに準拠していないPodの作成をブロックします
3. `match.any.resources.kinds: [Pod]`は、クラスタ全体のすべてのPodリソースにポリシーを適用します
4. `validate.podSecurity`は、`latest`標準バージョンの`baseline`レベルで、適度なセキュリティ制限を持つKubernetes Pod Security Standardsを強制します

それでは、Baselineポリシーを適用しましょう：

```bash
$ kubectl apply -f ~/environment/eks-workshop/modules/security/kyverno/baseline-policy/baseline-policy.yaml
clusterpolicy.kyverno.io/baseline-policy created
```

次に、特権Podを再度実行してみましょう：

```bash expectError=true
$ kubectl run privileged-pod --image=nginx --restart=Never --privileged
Error from server: admission webhook "validate.kyverno.svc-fail" denied the request:

resource Pod/default/privileged-pod was blocked due to the following policies

baseline-policy:
  baseline: |
    Validation rule 'baseline' failed. It violates PodSecurity "baseline:latest": ({Allowed:false ForbiddenReason:privileged ForbiddenDetail:container "privileged-pod" must not set securityContext.privileged=true})
```

ご覧の通り、クラスタに設定したBaselineポリシーに準拠していないため、作成が失敗しました。

### 自動生成されたポリシーに関する注意

Pod Security Admission（PSA）はPodレベルで動作しますが、実際にはPodはDeploymentなどのPodコントローラーによって管理されることが一般的です。Podコントローラーレベルでのポッドセキュリティエラーの表示がないと、問題のトラブルシューティングが複雑になる可能性があります。PSAの`enforce`モードは、Podの作成を防止する唯一のPSAモードですが、PSA強制はPodコントローラーレベルでは機能しません。この体験を向上させるため、PSAの`warn`および`audit`モードも`enforce`と共に使用することをお勧めします。こうすることで、コントローラーリソースが適用されたPSSレベルで失敗するPodを作成しようとしていることをPSAが示すようになります。

Kubernetesでのポリシーアズコード（PaC）ソリューションを使用する場合、クラスタ内で使用されるさまざまなリソースをカバーするポリシーを作成および維持する別の課題があります。[Kyverno Auto-Gen Rules for Pod Controllers](https://kyverno.io/docs/writing-policies/autogen/)機能を使用すると、PodポリシーがPodコントローラー（DeploymentやDaemonSetなど）ポリシーを自動生成します。このKyvernoの機能により、ポリシーの表現力が向上し、関連リソースのポリシーを維持する労力が軽減され、コントローラーリソースが進行を妨げられない一方で基となるPodが妨げられるPSAユーザーエクスペリエンスが向上します。
