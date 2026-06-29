---
title: "安全なPod間通信の有効化"
sidebar_position: 30
description: "ネットワークポリシーを使用してAmazon Elastic Kubernetes ServiceのPod間のネットワークトラフィックを制限します。"
tmdTranslationSourceHash: '9cc9d0ab7041602715d2c4a43bd989e4'
---

デフォルトでは、KubernetesはすべてのPodが制限なく自由に通信できるようになっています。Kubernetesのネットワークポリシーを使用すると、Pod間、Namespace間、およびIPブロック（CIDR範囲）間のトラフィックフローに関するルールを定義および適用できます。これらは仮想ファイアウォールとして機能し、Podラベル、Namespace、IPアドレス、ポートなどのさまざまな基準に基づいて、ingress（受信）およびegress（送信）のネットワークトラフィックルールを指定することで、クラスターをセグメント化して保護できます。

以下は、いくつかの主要な要素の説明を含むネットワークポリシーの例です：

::yaml{file="manifests/modules/networking/network-policies/apply-network-policies/example-network-policy.yaml" paths="metadata,spec.podSelector,spec.policyTypes,spec.ingress,spec.egress" title="example-network-policy.yaml"}

1. 他のKubernetesオブジェクトと同様に、`metadata`を使用すると、指定されたネットワークポリシーの名前とNamespaceを指定できます
2. `spec.podSelector`を使用すると、指定されたネットワークポリシーが適用されるNamespace内の特定のPodをラベルに基づいて選択できます。仕様で空のPodセレクターまたはmatchLabelsが指定されている場合、ポリシーはNamespace内のすべてのPodに適用されます。
3. `spec.policyTypes`は、選択されたPodに対してポリシーがingressトラフィック、egressトラフィック、またはその両方に適用されるかを指定します。このフィールドを指定しない場合、デフォルトの動作では、ネットワークポリシーがegressセクションを持たない限り、ingressトラフィックのみにネットワークポリシーが適用されます。egressセクションがある場合、ネットワークポリシーはingressとegressの両方のトラフィックに適用されます。
4. `ingress`を使用すると、どのPod（`podSelector`）、Namespace（`namespaceSelector`）、またはCIDR範囲（`ipBlock`）からのトラフィックが選択されたPodへ許可されるか、およびどのポートまたはポート範囲を使用できるかを指定するingressルールを設定できます。ポートまたはポート範囲が指定されていない場合、任意のポートを通信に使用できます。
5. `egress`を使用すると、選択されたPodからどのPod（`podSelector`）、Namespace（`namespaceSelector`）、またはCIDR範囲（`ipBlock`）へのトラフィックが許可されるか、およびどのポートまたはポート範囲を使用できるかを指定するegressルールを設定できます。ポートまたはポート範囲が指定されていない場合、任意のポートを通信に使用できます。

Kubernetesネットワークポリシーで許可または制限される機能の詳細については、[Kubernetesドキュメント](https://kubernetes.io/docs/concepts/services-networking/network-policies/)を参照してください。

ネットワークポリシーに加えて、Amazon VPC CNIのIPv4モードには「Security Groups for Pods」と呼ばれる強力な機能があります。この機能により、Amazon EC2セキュリティグループを使用して、ノードにデプロイされたPodへの、およびPodからのインバウンドおよびアウトバウンドネットワークトラフィックを管理する包括的なルールを定義できます。Security Groups for Podsとネットワークポリシーの間には機能の重複がありますが、いくつかの重要な違いがあります。

- セキュリティグループはCIDR範囲へのingressおよびegressトラフィックの制御を可能にしますが、ネットワークポリシーはPod、Namespace、およびCIDR範囲へのingressおよびegressトラフィックの制御を可能にします。
- セキュリティグループは他のセキュリティグループからのingressおよびegressトラフィックの制御を可能にしますが、これはネットワークポリシーでは利用できません。

Amazon EKSでは、Pod間のネットワーク通信を制限し、攻撃対象領域を減らし、潜在的な脆弱性を最小限に抑えるために、セキュリティグループと併せてネットワークポリシーを使用することを強く推奨しています。

