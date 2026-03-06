---
title: "イメージレジストリの制限"
sidebar_position: 73
tmdTranslationSourceHash: 'a15974d13f771db6b23e1d70452004a1'
---

EKSクラスターで未知のソースからのコンテナイメージを使用することは、特にこれらのイメージが共通脆弱性識別子（CVE）についてスキャンされていない場合、重大なセキュリティリスクをもたらす可能性があります。これらのリスクを軽減し、脆弱性の悪用の脅威を減らすためには、コンテナイメージが信頼できるレジストリから取得されていることを確認することが重要です。多くの組織では、自社がホストするプライベートイメージレジストリからのみイメージを使用することを義務付けるセキュリティガイドラインも存在します。

このセクションでは、Kyvernoを使用してクラスターで使用できるイメージレジストリを制限することで、安全なコンテナワークロードを実行する方法を探ります。

以前のラボで示したように、任意の利用可能なレジストリからのイメージを使用してワークロードをデプロイできます。まず、デフォルトレジストリ（`docker.io`を指す）を使用してサンプルDeploymentを作成してみましょう：

```bash hook=registry-setup
$ kubectl create deployment nginx-public --image=nginx
deployment.apps/nginx-public created

$ kubectl get deployment nginx-public -o jsonpath='{.spec.template.spec.containers[0].image}'
nginx
```

この場合、パブリックレジストリから基本的な`nginx`イメージを参照しました。しかし、悪意のある攻撃者が脆弱性のあるイメージをデプロイしてEKSクラスター上で実行し、クラスターのリソースを悪用する可能性があります。

ベストプラクティスを実装するために、未承認のイメージレジストリの使用を制限し、指定された信頼できるレジストリのみに依存するポリシーを定義します。

このラボでは、[Amazon ECR Public Gallery](https://public.ecr.aws/)を信頼できるレジストリとして使用し、他のレジストリでホストされているイメージを参照するDeploymentをブロックします。以下は、このユースケースのイメージプル制限のためのサンプルKyvernoポリシーです：

::yaml{file="manifests/modules/security/kyverno/images/restrict-registries.yaml" paths="spec.validationFailureAction,spec.background,spec.rules.0.match,spec.rules.0.validate.allowExistingViolations,spec.rules.0.validate.pattern"}

1. `validationFailureAction: Enforce`は非準拠のDeploymentの作成または更新をブロックします
2. `background: true`は既存のリソースに加えて新しいリソースにもポリシーを適用します
3. `match.any.resources.kinds: [Deployment]`はポリシーをクラスター全体のすべてのDeploymentリソースに適用します
4. `allowExistingViolations: false`は既に違反しているDeploymentの更新もブロックすることを保証し、既存の非準拠Deploymentが強制なしに更新される可能性のあるギャップを閉じます
5. `validate.pattern`は、Deployment Podテンプレート内のすべてのコンテナイメージが`public.ecr.aws/*`レジストリから取得されることを強制し、未承認のレジストリからのイメージを参照するDeploymentをブロックします

> 注：このポリシーはDeploymentを対象としています。InitContainerと一時的なコンテナはこのパターンでカバーされていません。

次のコマンドを使用してこのポリシーを適用しましょう：

```bash
$ kubectl apply -f ~/environment/eks-workshop/modules/security/kyverno/images/restrict-registries.yaml

clusterpolicy.kyverno.io/restrict-image-registries created
```

では、パブリックレジストリからのイメージを使用して新しいDeploymentを作成してみましょう：

```bash expectError=true hook=registry-blocked
$ kubectl create deployment nginx-blocked --image=nginx
error: failed to create deployment: admission webhook "validate.kyverno.svc-fail" denied the request:

resource Deployment/default/nginx-blocked was blocked due to the following policies

restrict-image-registries:
  validate-registries: 'validation error: Unknown Image registry. rule validate-registries
    failed at path /spec/template/spec/containers/0/image/'
```

見て分かるように、以前に作成したKyvernoポリシーによってDeploymentがブロックされました。

次に、ポリシーで定義した信頼できるレジストリ（public.ecr.aws）でホストされている`nginx`イメージを使用してDeploymentを作成してみましょう：

```bash
$ kubectl create deployment nginx-ecr --image=public.ecr.aws/nginx/nginx
deployment.apps/nginx-ecr created
```

成功しました！Podテンプレートが信頼できるレジストリからのイメージを参照しているため、Deploymentは正常に作成されました。

これで、パブリックレジストリからのイメージを参照するDeploymentをブロックし、許可されたイメージリポジトリのみの使用を制限する方法を確認しました。さらなるセキュリティのベストプラクティスとして、プライベートリポジトリのみを許可することを検討するかもしれません。

> 注：次のラボで使用するため、このタスクで作成された実行中のDeploymentを削除しないでください。

