---
title: Secrets
sidebar_position: 20
tmdTranslationSourceHash: '498d7a129e762c2cad7b7143f65b4f62'
---

# Secrets

**Secrets**は、パスワード、OAuthトークン、SSHキー、TLS証明書などの機密情報を保存および管理するために使用されます。これらは、Pod仕様やコンテナイメージに直接記述するよりも、機密データを安全に扱う方法を提供します。

Secretsは以下を提供します：
- **セキュリティ：** 機密データをアプリケーションコードとは別に保存
- **アクセス制御：** どのPodとユーザーが機密情報にアクセスできるかを制御
- **暗号化：** データはbase64エンコードされ、保存時に暗号化可能
- **柔軟性：** 環境変数、ファイル、またはイメージプルのためにSecretsを使用

このラボでは、小売店のカタログサービス用のデータベース認証情報を作成し、Podがこの機密情報に安全にアクセスする方法を学習します。

### 最初のSecretの作成

小売店のカタログサービス用のSecretを作成しましょう。カタログはMySQLデータベースに接続するためにデータベース認証情報が必要です：

::yaml{file="manifests/base-application/catalog/secrets.yaml" paths="kind,metadata.name,data" title="catalog-secret.yaml"}

1. `kind: Secret`：作成するリソースのタイプをKubernetesに指示
2. `metadata.name`：Namespace内でこのSecretを一意に識別する名前
5. `data`：機密データを含むキーと値のペア（base64エンコード済み）

Secret設定を適用します：
```bash
$ kubectl apply -k ~/environment/eks-workshop/modules/introduction/basics/secrets
```

### Secretの確認

それでは、作成したSecretを確認しましょう：

```bash
$ kubectl get secrets -n catalog
NAME         TYPE     DATA   AGE
catalog-db   Opaque   2      30s
```

Secretの詳細情報を取得します：
```bash
$ kubectl describe secret -n catalog catalog-db
Name:         catalog-db
Namespace:    catalog
Labels:       <none>
Annotations:  <none>

Type:  Opaque

Data
====
RETAIL_CATALOG_PERSISTENCE_PASSWORD:  16 bytes
RETAIL_CATALOG_PERSISTENCE_USER:      7 bytes
```

これは以下を示しています：
- **Type** - Secretの種類（汎用的な使用にはOpaque）
- **Data** - キーと値のペアの数（値はセキュリティのため非表示）
- **Labels** - 整理のためのメタデータタグ

セキュリティ上の理由から、実際の値は表示されないことに注意してください。base64エンコードされたデータを確認するには：
```bash
$ kubectl get secret catalog-db -n catalog -o yaml
apiVersion: v1
data:
  RETAIL_CATALOG_PERSISTENCE_PASSWORD: ZFltTmZXVjR1RXZUem9GdQ==
  RETAIL_CATALOG_PERSISTENCE_USER: Y2F0YWxvZw==
kind: Secret
metadata:
  annotations:
    kubectl.kubernetes.io/last-applied-configuration: |
      {"apiVersion":"v1","data":{"RETAIL_CATALOG_PERSISTENCE_PASSWORD":"ZFltTmZXVjR1RXZUem9GdQ==","RETAIL_CATALOG_PERSISTENCE_USER":"Y2F0YWxvZw=="},"kind":"Secret","metadata":{"annotations":{},"name":"catalog-db","namespace":"catalog"}}
  creationTimestamp: "2025-10-05T17:52:34Z"
  name: catalog-db
  namespace: catalog
  resourceVersion: "902820"
  uid: 726e4fef-f82b-4a7e-a063-f72f18a941cd
type: Opaque
```

データがbase64エンコードされていることがわかります。値をデコードするには：
```bash
$ kubectl get secret catalog-db -n catalog -o jsonpath='{.data.RETAIL_CATALOG_PERSISTENCE_USER}' | base64 --decode
catalog
```

### PodでのSecretsの使用

それでは、Secretを使用するPodを作成しましょう。カタログPodを更新してデータベース認証情報を使用します：

::yaml{file="manifests/modules/introduction/basics/secrets/catalog-pod-with-secret.yaml" paths="kind,metadata.name,spec.containers,spec.containers.0.envFrom" title="catalog-pod-with-secret.yaml"}

ここでの主な違いは：
- `envFrom.configMapRef`：ConfigMapからすべてのキーと値のペアを環境変数として読み込み
- `envFrom.secretRef`：Secretからすべてのキーと値のペアを環境変数として読み込み
- このアプローチは、個々のキーをマッピングせずにすべてのSecretデータを自動的に利用可能にします

更新したPod設定を適用します：
```bash
$ kubectl apply -f ~/environment/eks-workshop/modules/introduction/basics/secrets/catalog-pod-with-secret.yaml
```

### Secretアクセスのテスト

それでは、PodがSecret値にアクセスできることを確認しましょう：

```bash hook=ready
$ kubectl exec -n catalog catalog-pod -- env | grep RETAIL_CATALOG_PERSISTENCE_USER
RETAIL_CATALOG_PERSISTENCE_USER=catalog_user
```

カタログ関連のすべての環境変数も確認できます：
```bash
$ kubectl exec -n catalog catalog-pod -- env | grep RETAIL_CATALOG
RETAIL_CATALOG_PERSISTENCE_PROVIDER=mysql
RETAIL_CATALOG_PERSISTENCE_ENDPOINT=catalog-mysql:3306
RETAIL_CATALOG_PERSISTENCE_DB_NAME=catalog
RETAIL_CATALOG_PERSISTENCE_USER=catalog_user
RETAIL_CATALOG_PERSISTENCE_PASSWORD=dYmNfWV4uEvTzoFu
```

:::warning
本番環境では、パスワードをログやコンソール出力に出力することは避けてください。これは教育目的でのみ示されています。
:::

## SecretsとConfigMapsの比較

| Secrets | ConfigMaps |
|---------|------------|
| 機密データ（パスワード、トークン） | 非機密データ |
| base64エンコード + 追加のセキュリティ | 保存用にbase64エンコード |
| kubectl出力では値が非表示 | プレーンテキストで表示 |
| 認証情報、証明書、キー | 設定ファイル、環境変数 |

## 高度なSecretsの管理

Kubernetes Secretsは機密データの基本的なセキュリティを提供しますが、本番環境ではより高度なシークレット管理ソリューションが必要になることがよくあります。自動ローテーション、きめ細かいアクセス制御、外部シークレットストアとの統合などの強化されたセキュリティ機能については、以下を参照してください：

**[AWS Secrets Manager統合](../../../../security/secrets-management/secrets-manager/)** - 自動ローテーションと集中管理を備えたエンタープライズグレードのシークレット管理のために、AWS Secrets ManagerをEKSクラスターと統合する方法を学びます。

## 覚えておくべき重要なポイント

* Secretsは機密データをアプリケーションコードとは別に保存します
* 値はbase64エンコードされ、保存時に暗号化可能です
* Secret値はセキュリティのためkubectl describeの出力では非表示になります
* 環境変数として使用するか、ファイルとしてマウントできます
* 非機密の設定データにはConfigMapsを使用します
* 本番ワークロードの場合、AWS Secrets Managerのような高度なソリューションの使用を検討してください

