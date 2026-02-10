---
title: "イメージレジストリの制限"
sidebar_position: 73
tmdTranslationSourceHash: 9977a758250f3ddcd1563394e262c188
---

EKSクラスターで未知のソースからのコンテナイメージを使用することは、特にこれらのイメージが共通脆弱性識別子（CVE）についてスキャンされていない場合、重大なセキュリティリスクをもたらす可能性があります。これらのリスクを軽減し、脆弱性の悪用の脅威を減らすためには、コンテナイメージが信頼できるレジストリから取得されていることを確認することが重要です。多くの組織では、自社がホストするプライベートイメージレジストリからのみイメージを使用することを義務付けるセキュリティガイドラインも存在します。

このセクションでは、Kyvernoを使用してクラスターで使用できるイメージレジストリを制限することで、安全なコンテナワークロードを実行する方法を探ります。

以前のラボで示したように、任意の利用可能なレジストリからイメージを使用してPodを実行できます。まず、デフォルトレジストリ（`docker.io`を指す）を使用してサンプルPodを実行してみましょう：

```bash
$ kubectl run nginx --image=nginx

NAME    READY   STATUS    RESTARTS   AGE
nginx   1/1     Running   0          47s

$ kubectl describe pod nginx | grep Image
    Image:          nginx
    Image ID:       docker.io/library/nginx@sha256:4c0fdaa8b6341bfdeca5f18f7837462c80cff90527ee35ef185571e1c327beac
```

この場合、パブリックレジストリから基本的な`nginx`イメージを取得しました。しかし、悪意のある攻撃者が脆弱性のあるイメージを取得してEKSクラスター上で実行し、クラスターのリソースを悪用する可能性があります。

ベストプラクティスを実装するために、未承認のイメージレジストリの使用を制限し、指定された信頼できるレジストリのみに依存するポリシーを定義します。

このラボでは、[Amazon ECR Public Gallery](https://public.ecr.aws/)を信頼できるレジストリとして使用し、他のレジストリでホストされているイメージを使用するコンテナをブロックします。以下は、このユースケースのイメージプル制限のためのサンプルKyvernoポリシーです：

::yaml{file="manifests/modules/security/kyverno/images/restrict-registries.yaml" paths="spec.validationFailureAction,spec.background,spec.rules.0.match,spec.rules.0.validate.pattern"}

1. `validationFailureAction: Enforce`は非準拠のPodの作成をブロックします
2. `background: true`は既存のリソースに加えて新しいリソースにもポリシーを適用します
3. `match.any.resources.kinds: [Pod]`はポリシーをクラスター全体のすべてのPodリソースに適用します
4. `validate.pattern`は、すべてのコンテナイメージが`public.ecr.aws/*`レジストリから取得されることを強制し、未承認のレジストリからのイメージをブロックします

> 注：このポリシーは、InitContainerや一時的なコンテナの使用を参照されたリポジトリに制限しません。

次のコマンドを使用してこのポリシーを適用しましょう：

```bash
$ kubectl apply -f ~/environment/eks-workshop/modules/security/kyverno/images/restrict-registries.yaml

clusterpolicy.kyverno.io/restrict-image-registries created
```

では、パブリックレジストリからのデフォルトイメージを使用して別のサンプルPodを実行してみましょう：

```bash expectError=true
$ kubectl run nginx-public --image=nginx

Error from server: admission webhook "validate.kyverno.svc-fail" denied the request:

resource Pod/default/nginx-public was blocked due to the following policies

restrict-image-registries:
  validate-registries: 'validation error: Unknown Image registry. rule validate-registries
    failed at path /spec/containers/0/image/'
```

見て分かるように、Podは実行できず、以前に作成したKyvernoポリシーによってPod作成がブロックされたという出力が表示されました。

次に、ポリシーで定義した信頼できるレジストリ（public.ecr.aws）でホストされている`nginx`イメージを使用してサンプルPodを実行してみましょう：

```bash
$ kubectl run nginx-ecr --image=public.ecr.aws/nginx/nginx
pod/nginx-public created
```

成功しました！Podは正常に作成されました。

これで、EKSクラスターでパブリックレジストリからのイメージの実行をブロックし、許可されたイメージリポジトリのみの使用を制限する方法を確認しました。さらなるセキュリティのベストプラクティスとして、プライベートリポジトリのみを許可することを検討するかもしれません。

> 注：次のラボでそれらを使用するため、このタスクで作成された実行中のPodを削除しないでください。
