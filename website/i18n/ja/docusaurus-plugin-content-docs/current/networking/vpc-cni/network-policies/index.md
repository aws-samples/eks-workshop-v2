---
title: "ネットワークポリシー"
sidebar_position: 10
sidebar_custom_props: { "module": true }
description: "ネットワークポリシーを使用してAmazon Elastic Kubernetes Serviceのポッド間のネットワークトラフィックを制限します。"
tmdTranslationSourceHash: 2431e68bee7e383213ec838021213041
---

::required-time

:::tip 始める前に
このセクションの環境を準備してください：

```bash wait=30 timeout=600
$ prepare-environment networking/network-policies
```

:::

デフォルトでは、Kubernetesはすべてのポッドが制限なく自由に通信できるようになっています。Kubernetesネットワークポリシーを使用すると、ポッド、名前空間、IPブロック（CIDRレンジ）間のトラフィックフローに関するルールを定義および適用できます。これらは仮想ファイアウォールとして機能し、ポッドラベル、名前空間、IPアドレス、ポートなどの様々な条件に基づいてイングレス（受信）およびエグレス（送信）ネットワークトラフィックルールを指定することで、クラスターをセグメント化して保護することができます。

以下はネットワークポリシーの例と主要要素の説明です：

::yaml{file="manifests/modules/networking/network-policies/apply-network-policies/example-network-policy.yaml" paths="metadata,spec.podSelector,spec.policyTypes,spec.ingress,spec.egress" title="example-network-policy.yaml"}

1. 他のKubernetesオブジェクトと同様に、`metadata`では特定のネットワークポリシーの名前と名前空間を指定できます
2. `spec.podSelector`では、ネットワークポリシーが適用される名前空間内の特定のポッドをラベルに基づいて選択できます。空のポッドセレクタまたはmatchLabelsが指定されている場合、ポリシーはその名前空間内のすべてのポッドに適用されます。
3. `spec.policyTypes`は、ポリシーをイングレストラフィック、エグレストラフィック、またはその両方に適用するかどうかを指定します。このフィールドを指定しない場合、デフォルトの動作はネットワークポリシーをイングレストラフィックのみに適用することですが、ネットワークポリシーにエグレスセクションがある場合、ネットワークポリシーはイングレスとエグレスの両方のトラフィックに適用されます。
4. `ingress`では、選択されたポッドへのトラフィックが許可されるポッド（`podSelector`）、名前空間（`namespaceSelector`）、またはCIDRレンジ（`ipBlock`）と、通信に使用できるポートまたはポート範囲を指定するイングレスルールを設定できます。ポートまたはポート範囲が指定されていない場合、通信にはどのポートも使用できます。
5. `egress`では、選択されたポッドからのトラフィックが許可されるポッド（`podSelector`）、名前空間（`namespaceSelector`）、またはCIDRレンジ（`ipBlock`）と、通信に使用できるポートまたはポート範囲を指定するエグレスルールを設定できます。ポートまたはポート範囲が指定されていない場合、通信にはどのポートも使用できます。

Kubernetesネットワークポリシーで許可または制限される機能の詳細については、[Kubernetesドキュメント](https://kubernetes.io/docs/concepts/services-networking/network-policies/)を参照してください。

ネットワークポリシーに加えて、IPv4モードのAmazon VPC CNIは「ポッド用セキュリティグループ」という強力な機能を提供しています。この機能を使用すると、Amazon EC2セキュリティグループを使用して、ノードにデプロイされたポッドとの間の着信および発信ネットワークトラフィックを制御する包括的なルールを定義できます。ポッド用セキュリティグループとネットワークポリシーの機能には重複する部分がありますが、いくつかの重要な違いがあります。

- セキュリティグループはCIDRレンジへの入出力トラフィックの制御を可能にしますが、ネットワークポリシーはポッド、名前空間、およびCIDRレンジへの入出力トラフィックの制御を可能にします。
- セキュリティグループは他のセキュリティグループからの入出力トラフィックの制御を可能にしますが、これはネットワークポリシーでは利用できません。

Amazon EKSでは、ポッド間のネットワーク通信を制限し、攻撃対象領域を減らし、潜在的な脆弱性を最小限に抑えるために、セキュリティグループと組み合わせてネットワークポリシーを採用することを強く推奨しています。
