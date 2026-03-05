---
title: "Pod Security Standards"
sidebar_position: 60
sidebar_custom_props: { "module": true }
description: "Amazon Elastic Kubernetes ServiceでPod Security Standardsを使用して、実行されるPodのセキュリティ制限を定義します。"
tmdTranslationSourceHash: "95eeb48d92945f94c5f8b225f506b126"
---

::required-time

:::tip 始める前に
このセクションの環境を準備します：

```bash timeout=300 wait=30
$ prepare-environment security/pss-psa
```

:::

Kubernetesを安全に採用するには、クラスターへの望ましくない変更を防ぐことが含まれます。望ましくない変更は、クラスターの運用、ワークロードの動作を妨げ、環境全体の整合性を損なう可能性さえあります。正しいセキュリティ設定がないPodを導入することは、望ましくないクラスターの変更の一例です。Podのセキュリティを制御するために、Kubernetesは[Pod Security Policy / PSP](https://kubernetes.io/docs/concepts/policy/pod-security-policy/)リソースを提供していました。PSPは、Podがクラスターで作成または更新される前に満たさなければならないセキュリティ設定のセットを指定します。ただし、Kubernetesバージョン1.21以降、PSPは非推奨となり、Kubernetesバージョン1.25で削除される予定です。

Kubernetesでは、PSPは[Pod Security Admission / PSA](https://kubernetes.io/docs/concepts/security/pod-security-admission/)に置き換えられており、これは[Pod Security Standards / PSS](https://kubernetes.io/docs/concepts/security/pod-security-standards/)で概説されているセキュリティ制御を実装する組み込みのアドミッションコントローラーです。Kubernetesバージョン1.23以降、PSAとPSSはどちらもベータ機能状態に達し、Amazon Elastic Kubernetes Service (EKS) ではデフォルトで有効になっています。

### Pod Security Standards (PSS) と Pod Security Admission (PSA)

Kubernetesのドキュメントによると、PSSは「セキュリティスペクトルを広くカバーするために3つの異なるポリシーを定義しています。これらのポリシーは累積的であり、高度に許容的なものから高度に制限的なものまで範囲があります。」

ポリシーレベルは次のように定義されています：

- **Privileged：** 制限のない（安全でない）ポリシーで、最大限の権限レベルを提供します。このポリシーは既知の特権エスカレーションを許可します。これはポリシーがない状態です。これはロギングエージェント、CNI、ストレージドライバー、その他のシステム全体のアプリケーションなど、特権アクセスが必要なアプリケーションに適しています。
- **Baseline：** 既知の特権エスカレーションを防ぐ最小限に制限的なポリシーです。デフォルト（最小限に指定された）Podの設定を許可します。baselineポリシーは、hostNetwork、hostPID、hostIPC、hostPath、hostPortの使用、Linuxケイパビリティの追加能力の欠如、およびその他いくつかの制限を禁止しています。
- **Restricted：** 現在のPod強化のベストプラクティスに従った、非常に制限されたポリシーです。このポリシーはbaselineを継承し、rootやroot-groupとして実行できないなどのさらなる制限を追加します。restrictedポリシーはアプリケーションの機能に影響を与える可能性があります。それらは主にセキュリティ上重要なアプリケーションの実行を対象としています。

PSAアドミッションコントローラーは、PSSポリシーで概説されている制御を、以下の3つの動作モードを通じて実装します。

- **enforce：** ポリシー違反があると、Podは拒否されます。
- **audit：** ポリシー違反があると、[監査ログ](https://kubernetes.io/docs/tasks/debug/debug-cluster/audit/)に記録されたイベントに監査アノテーションが追加されますが、それ以外は許可されます。
- **warn：** ポリシー違反があると、ユーザー向けの警告がトリガーされますが、それ以外は許可されます。

### 組み込みのPod Securityアドミッション強制

Kubernetesバージョン1.23以降、PodSecurity[フィーチャーゲート](https://kubernetes.io/docs/reference/command-line-tools-reference/feature-gates/)はAmazon EKSでデフォルトで有効になっています。アップストリームKubernetesバージョン1.23のデフォルトの[PSSとPSA設定](https://kubernetes.io/docs/tasks/configure-pod-container/enforce-standards-admission-controller/#configure-the-admission-controller)もAmazon EKSで使用されており、以下のようになっています。

> _PodSecurityフィーチャーゲートは、Kubernetes v1.23とv1.24ではBetaバージョン（apiVersion: v1beta1）であり、Kubernetes v1.25で一般に利用可能（GA、apiVersion: v1）になりました。_

```yaml
defaults:
  enforce: "privileged"
  enforce-version: "latest"
  audit: "privileged"
  audit-version: "latest"
  warn: "privileged"
  warn-version: "latest"
exemptions:
  # Array of authenticated usernames to exempt.
  usernames: []
  # Array of runtime class names to exempt.
  runtimeClasses: []
  # Array of namespaces to exempt.
  namespaces: []
```

上記の設定は、以下のクラスター全体のシナリオを構成します：

- Kubernetes APIサーバーの起動時にPSA免除は設定されていません。
- すべてのPSAモードに対してデフォルトでPrivileged PSSプロファイルが設定され、最新バージョンに設定されています。

### NamespaceのPod Security Admissionラベル

上記のデフォルト設定を考慮すると、PSAとPSSによって提供されるPodセキュリティをNamespaceがオプトインするために、Kubernetes NamespaceレベルでPSSプロファイルとPSAモードを設定する必要があります。Namespaceを設定して、Podセキュリティに使用するアドミッション制御モードを定義できます。[Kubernetesラベル](https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/)を使用して、特定のNamespace内のPodに使用したい事前定義されたPSSレベルを選択できます。選択したラベルは、潜在的な違反が検出された場合にPSAがどのアクションを実行するかを定義します。以下に示すように、任意のモードまたはすべてのモードを設定したり、異なるモードに異なるレベルを設定したりすることができます。各モードには、使用されるポリシーを決定する2つの可能なラベルがあります。

```text
# モードごとのレベルラベルは、モードに適用するポリシーレベルを示します。
#
# MODEは`enforce`、`audit`、または`warn`のいずれかでなければなりません。
# LEVELは`privileged`、`baseline`、または`restricted`のいずれかでなければなりません。
*pod-security.kubernetes.io/<MODE>*: <LEVEL>

# オプション：モードごとのバージョンラベルを使用して、特定のKubernetesマイナーバージョン（例：v1.24）で出荷されたポリシーにポリシーを固定することができます。
#
# MODEは`enforce`、`audit`、または`warn`のいずれかでなければなりません。
# VERSIONは有効なKubernetesマイナーバージョン、または`latest`でなければなりません。
*pod-security.kubernetes.io/<MODE>-version*: <VERSION>
```

以下は、テストに使用できるPSAとPSS Namespace設定の例です。オプションのPSAモードバージョンラベルは含めていないことに注意してください。デフォルトで設定されているクラスター全体の設定である「latest」を使用しています。以下の必要なラベルのコメントを外すことで、各Namespaceに必要なPSAモードとPSSプロファイルを有効にできます。

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: psa-pss-test-ns
  labels:
    # pod-security.kubernetes.io/enforce: privileged
    # pod-security.kubernetes.io/audit: privileged
    # pod-security.kubernetes.io/warn: privileged

    # pod-security.kubernetes.io/enforce: baseline
    # pod-security.kubernetes.io/audit: baseline
    # pod-security.kubernetes.io/warn: baseline

    # pod-security.kubernetes.io/enforce: restricted
    # pod-security.kubernetes.io/audit: restricted
    # pod-security.kubernetes.io/warn: restricted
```

### 検証アドミッションコントローラー

Kubernetesでは、アドミッションコントローラーは、Kubernetes APIサーバーへのリクエストがetcdに永続化され、クラスターの変更に使用される前にインターセプトするコードの一部です。アドミッションコントローラーは、変異型、検証型、またはその両方の種類にすることができます。PSAの実装は検証アドミッションコントローラーであり、インバウンドのPod仕様リクエストが指定されたPSSに準拠しているかどうかをチェックします。

以下のフローでは、[変異型および検証型動的アドミッションコントローラー](https://kubernetes.io/docs/reference/access-authn-authz/extensible-admission-controllers/)（アドミッションウェブフックとも呼ばれます）がウェブフックを介してKubernetes APIサーバーリクエストフローに統合されています。これらのウェブフックは、特定のタイプのAPIサーバーリクエストに応答するように設定されたサービスを呼び出します。たとえば、ウェブフックを使用して、Pod内のコンテナがnon-rootユーザーとして実行されていることを検証したり、コンテナが信頼できるレジストリからのものであることを検証したりするために、動的アドミッションコントローラーを設定できます。

![Kubernetes admission controllers](/docs/security/pod-security-standards/k8s-admission-controllers.webp)

### PSAとPSSの使用

PSAはPSSで概説されているポリシーを強制し、PSSポリシーはPodセキュリティプロファイルのセットを定義します。以下の図では、PSAとPSSがPodおよびNamespaceと連携して、Podセキュリティプロファイルを定義し、これらのプロファイルに基づいてアドミッション制御を適用する方法を概説しています。以下の図に示すように、PSA実施モードとPSSポリシーはターゲットNamespace内のラベルとして定義されています。

![PSS and PSA](/docs/security/pod-security-standards/using-pss-psa.webp)
