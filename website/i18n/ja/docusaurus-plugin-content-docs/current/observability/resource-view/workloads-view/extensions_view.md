---
title: "CustomResourceDefinitions"
sidebar_position: 70
tmdTranslationSourceHash: 0a0ac67f3a73f687ee714b7b9dc9f2b5
---

[拡張機能](https://kubernetes.io/docs/concepts/extend-kubernetes/)は、Kubernetesを拡張し深く統合するソフトウェアコンポーネントです。この実習では、**_Custom Resource Definitions_**、**_Mutating Webhook Configurations_**、および**_Validating Webhook Configurations_**などの一般的な拡張リソースタイプを確認します。

**[CustomResourceDefinitions](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/#customresourcedefinitions)** APIリソースは、カスタムリソースを定義することができます。CRDオブジェクトを定義すると、指定した名前とスキーマを持つ新しいカスタムリソースが作成されます。Kubernetes APIはあなたのカスタムリソースの提供とストレージを処理します。CRDオブジェクトの名前は有効な**DNSサブドメイン名**である必要があります。

**_Resources_** - **_Extensions_**の下で、クラスター上の**_Custom Resource Definitions_**のリストを確認できます。

**_Webhook_**設定は、オブジェクトリクエストを受け入れるか拒否するために、*[Kubernetes Admission controllers](https://kubernetes.io/blog/2019/03/21/a-guide-to-kubernetes-admission-controllers/)*による認証済みAPIリクエストの傍受プロセス中に実行されます。Kubernetes admission controllersは、名前空間またはクラスター全体にセキュリティベースラインを設定します。次の図は、admission controllerプロセスに含まれる異なるステップを説明しています。

![Insights](/img/resource-view/ext-admincontroller.png)

[Mutating admission webhooks](https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/#mutatingadmissionwebhook)は、カスタムデフォルトを強制するためにAPIサーバーに送信されたオブジェクトを修正します。

**_Resources_** - **_Extensions_**の下で、クラスター上の**_Mutating Webhook Configurations_**のリストを確認できます。

以下のスクリーンショットは、*aws-load-balancer-webhook*の詳細を示しています。このwebhook設定では、`Match policy = Equivalent`となっており、これはwebhookバージョン`Admission review version = v1beta1`に従ってオブジェクトを修正することで、リクエストがwebhookに送信されることを意味します。

設定で`Match policy = Equivalent`の場合、新しいリクエストが処理されるときに設定で指定されたものとは異なるwebhookバージョンを持つ場合、リクエストはwebhookに送信されません。*Side Effects*が`None`に設定され、*Timeout Seconds*が`10`に設定されていることに注目してください。これは、このwebhookに副作用がなく、10秒後に拒否されることを意味します。

![Insights](/img/resource-view/ext-mutatingwebhook-detail.jpg)

**[Validating admission webhooks](https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/#validatingadmissionwebhook)**は、APIサーバーへのリクエストを検証します。その設定には、リクエストを検証するための設定が含まれています。**_ValidatingAdmissionWebhooks_**の設定は**_MutatingAdmissionWebhook_**と類似していますが、**_ValidatingAdmissionWebhooks_**リクエストオブジェクトの最終状態はetcdに保存されます。
