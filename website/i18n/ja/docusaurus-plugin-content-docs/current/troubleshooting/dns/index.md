---
title: "DNS解決"
sidebar_position: 60
chapter: true
sidebar_custom_props: { "module": true }
description: "DNS解決問題によりサービス通信が中断されています。"
tmdTranslationSourceHash: c92393711351c854b411e33abe38f6cd
---

::required-time

このラボでは、サービス通信が中断されるシナリオを調査します。ネットワーキングの問題をトラブルシューティングし、根本原因がDNS解決に関連していることを特定します。次に、さまざまなタイプのDNS解決障害を診断する重要なトラブルシューティング手順、修正の実装、およびサービス通信の復旧を行います。EKSでのDNSトラブルシューティングに関する追加情報については、[Amazon EKSでのDNS障害のトラブルシューティング方法](https://repost.aws/knowledge-center/eks-dns-failure)を参照してください。

:::tip 開始前に
このセクションの環境を準備します：

```bash timeout=900 wait=10
$ prepare-environment troubleshooting/dns
```

このモジュールのprepare-environmentスクリプトはワークショップ環境をリセットします。
:::

### EKSにおけるDNS解決

EKSクラスタでは、アプリケーションが他のサービス（クラスタ内部または外部）に接続する必要がある場合、DNSを介してターゲットエンドポイント名をIPアドレスに解決する必要があります。

デフォルトでは、KubernetesクラスタはすべてのPodが名前サーバーとしてkube-dnsサービスのClusterIPアドレスを使用するように設定します。Amazon EKSクラスタを起動すると、EKSはkube-dnsサービスの背後で機能するCoreDNSの2つのPodレプリカをデプロイします。

[CoreDNS](https://coredns.io/)は、柔軟で拡張可能なDNSサーバーであり、Kubernetesクラスタの標準DNSとして広く採用されています。

次のセクションでトラブルシューティングの旅を始めましょう。
