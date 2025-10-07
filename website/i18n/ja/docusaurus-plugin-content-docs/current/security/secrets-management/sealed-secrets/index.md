---
title: "Sealed Secretsを使用した機密情報の保護"
sidebar_position: 430
sidebar_custom_props: { "module": true }
description: "Sealed Secretsを使用してAmazon Elastic Kubernetes Serviceで実行されるアプリケーションに認証情報などの機密設定を提供します。"
kiteTranslationSourceHash: dc44116b8fde19ef8fe586b2a8c16dc6
---

::required-time

:::caution
[Sealed Secrets](https://docs.bitnami.com/tutorials/sealed-secrets)プロジェクトはAWSサービスとは関係なく、[Bitnami Labs](https://bitnami.com/)によるサードパーティのオープンソースツールです。
:::

:::tip 始める前に
このセクションの環境を準備してください：

```bash timeout=300 wait=30
$ prepare-environment security/sealed-secrets
```

:::

[Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets)は、Secretオブジェクトを暗号化し、パブリックリポジトリを含む安全な場所に保存するためのメカニズムを提供します。SealedSecretは、Kubernetesクラスタで実行されているコントローラーによってのみ復号化でき、他の誰もSealedSecretから元のSecretを取得することはできません。

この章では、SealedSecretsを使用してKubernetes Secretに関連するYAMLマニフェストを暗号化し、[kubectl](https://kubernetes.io/docs/reference/kubectl/)などのツールを使用した通常のワークフローでこれらの暗号化されたSecretをEKSクラスタにデプロイできるようにします。

