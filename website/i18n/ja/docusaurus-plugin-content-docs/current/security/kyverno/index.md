---
title: "Kyvernoによるポリシー管理"
sidebar_position: 70
sidebar_custom_props: { "module": true }
description: "Amazon Elastic Kubernetes ServiceでKyvernoを使用してポリシーアズコードを適用します。"
tmdTranslationSourceHash: "616bd6d5b4ce3fcba7d65bd048d989fb"
---

::required-time

:::tip 開始する前に
この章のための環境を準備してください：

```bash timeout=600 wait=30
$ prepare-environment security/kyverno
```

これにより、お使いのラボ環境に以下の変更が適用されます：

以下のKubernetesアドオンをEKSクラスタにインストールします：

- Kyverno Policy Manager
- Kyverno Policies
- Policy Reporter

これらの変更を適用するTerraformは[こちら](https://github.com/aws-samples/eks-workshop-v2/tree/main/manifests/modules/security/kyverno/.workshop/terraform)で確認できます。
:::

コンテナが本番環境でますます採用されるにつれて、DevOps、セキュリティ、プラットフォームチームは、ガバナンスと[ポリシーアズコード（PaC）](https://aws.github.io/aws-eks-best-practices/security/docs/pods/#policy-as-code-pac)を協力して管理するための効果的なソリューションを必要としています。これにより、すべてのチームがセキュリティに関する同じ真実の源を共有し、個々のニーズを説明する際に一貫したベースラインの「言語」を使用することができます。

Kubernetesは、その性質上、構築とオーケストレーションのためのツールとして設計されており、最初から定義されたガードレールがありません。ビルダーにセキュリティを制御する方法を提供するために、Kubernetesはバージョン1.23から[Pod Security Admission（PSA）](https://kubernetes.io/docs/concepts/security/pod-security-admission/)を提供しています。PSAは[Pod Security Standards（PSS）](https://kubernetes.io/docs/concepts/security/pod-security-standards/)で概説されているセキュリティコントロールを実装した組み込みのアドミッションコントローラであり、Amazon Elastic Kubernetes Service（EKS）ではデフォルトで有効になっています。

### Kyvernoとは何か？

[Kyverno](https://kyverno.io/)（ギリシャ語で「統治する」）は、Kubernetes専用に設計されたポリシーエンジンです。これはCloud Native Computing Foundation（CNCF）のプロジェクトであり、チームが協力してポリシーアズコードを実施することを可能にします。

Kyvernoポリシーエンジンは、[Dynamic Admission Controller](https://kubernetes.io/docs/reference/access-authn-authz/extensible-admission-controllers/)としてKubernetes APIサーバーと統合され、インバウンドのKubernetes APIリクエストを**変更**および**検証**するポリシーを可能にします。これにより、データがクラスタに永続化され適用される前に、定義されたルールへの準拠が確保されます。

KyvernoはYAMLで記述された宣言的なKubernetesリソースを使用し、新しいポリシー言語を学ぶ必要がありません。結果はKubernetesリソースとイベントとして利用可能です。

Kyvernoポリシーは、リソース構成を**検証**、**変更**、**生成**するために使用でき、また画像の署名と証明を**検証**することもできます。これにより、包括的なソフトウェアサプライチェーンセキュリティ標準の施行に必要なすべての構成要素が提供されます。

### Kyvernoの仕組み

Kyvernoは、Kubernetesクラスタで動的アドミッションコントローラとして動作します。Kubernetes APIサーバーから検証および変更アドミッションwebhook HTTPコールバックを受信し、一致するポリシーを適用して、アドミッションポリシーを実施するか、リクエストを拒否する結果を返します。また、リクエストを監査し、実施前に環境のセキュリティ状態を監視するためにも使用できます。

以下の図は、Kyvernoの高レベルの論理アーキテクチャを示しています：

![KyvernoArchitecture](/docs/security/kyverno/ky-arch.webp)

主要なコンポーネントは、Webhookサーバーとウェブフックコントローラーの2つです。**Webhookサーバー**は、Kubernetes APIサーバーから受信したAdmissionReviewリクエストを処理し、処理のためにエンジンに送信します。これは**Webhookコントローラー**によって動的に構成され、このコントローラーはインストールされたポリシーを監視し、それらのポリシーに一致するリソースのみをリクエストするようにWebhookを修正します。

---

ラボを進める前に、`prepare-environment`スクリプトによってプロビジョニングされたKyvernoリソースを検証しましょう：

```bash
$ kubectl -n kyverno get all
NAME                                                 READY   STATUS    RESTARTS   AGE
pod/kyverno-admission-controller-8648694c5-hv8vb     1/1     Running   0          97s
pod/kyverno-background-controller-6fbcb79d89-kt7w9   1/1     Running   0          97s
pod/kyverno-cleanup-controller-549855c6d8-2jjtn      1/1     Running   0          96s
pod/kyverno-reports-controller-668c67d758-4s57g      1/1     Running   0          96s

NAME                                            TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE
service/kyverno-background-controller-metrics   ClusterIP   172.16.74.233    <none>        8000/TCP   98s
service/kyverno-cleanup-controller              ClusterIP   172.16.29.137    <none>        443/TCP    98s
service/kyverno-cleanup-controller-metrics      ClusterIP   172.16.119.134   <none>        8000/TCP   98s
service/kyverno-reports-controller-metrics      ClusterIP   172.16.42.244    <none>        8000/TCP   98s
service/kyverno-svc                             ClusterIP   172.16.151.20    <none>        443/TCP    99s
service/kyverno-svc-metrics                     ClusterIP   172.16.60.130    <none>        8000/TCP   98s

NAME                                            READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/kyverno-admission-controller    1/1     1            1           98s
deployment.apps/kyverno-background-controller   1/1     1            1           98s
deployment.apps/kyverno-cleanup-controller      1/1     1            1           97s
deployment.apps/kyverno-reports-controller      1/1     1            1           97s

NAME                                                       DESIRED   CURRENT   READY   AGE
replicaset.apps/kyverno-admission-controller-8648694c5     1         1         1       98s
replicaset.apps/kyverno-background-controller-6fbcb79d89   1         1         1       98s
replicaset.apps/kyverno-cleanup-controller-549855c6d8      1         1         1       97s
replicaset.apps/kyverno-reports-controller-668c67d758      1         1         1       97s
```

