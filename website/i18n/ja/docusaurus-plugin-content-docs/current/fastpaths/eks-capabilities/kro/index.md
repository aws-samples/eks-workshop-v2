---
title: "kroを使用したスタックの構成"
sidebar_position: 30
tmdTranslationSourceHash: '8aaf2020da534e9eecf8c63c67840998'
---

::required-time{estimatedLabExecutionTimeMinutes="4"}

[ACKラボ](../ack/)では、`carts`をAWSマネージド DynamoDB テーブルに移行するために、**3つの別々のマニフェスト**（`Table`リソース、ConfigMapのオーバーライド、Pod Identityアソシエーション）を適用しました。これは一回限りの作業には適切ですが、多くのサービスでこれを実行するプラットフォームチームは、スタック全体をキャプチャする**1つのユーザー向けリソース**を必要とするでしょう。

このラボでは、EKS機能として提供される**kro (Kube Resource Orchestrator)** を使用して、まさにそれを実現します。kroを使用すると、プラットフォームチームは多くのKubernetesリソースを1つのシンプルなカスタムリソースの背後にパッケージ化できます。2つの要素があります：

- **`ResourceGraphDefinition` (RGD)** は設計図です。新しいカスタムリソースタイプ（ここでは`CartsStack`）、それが受け入れるわずかな入力（テーブル名など）、および1つのインスタンスが展開される基盤となるリソースのグラフを定義します：Namespace、ACK `Table`、ConfigMap、ServiceAccount、Deployment、およびService。プラットフォームチームはこれを一度記述します。
- **インスタンス**は、他のすべての人が適用するものです：入力のみが記入された短い`CartsStack`リソース。kroはそれを読み取り、正しい順序でグラフ全体を作成します。

他の機能と同様に、kroのコントローラーはクラスター外のAWS所有インフラストラクチャで実行され、AWSがその運用を処理します。クラスター内には、登録されたCustom Resource Definitions (CRD)のみが表示され、`resourcegraphdefinitions.kro.run`から始まります。

:::tip 事前にセットアップされた内容

- **kro EKSマネージド機能**がクラスターで`ACTIVE`になっており、`resourcegraphdefinitions.kro.run` CRDが登録されています。
- ACKラボの**ACK DynamoDB機能**はまだ`ACTIVE`なので、kroはそのネイティブKubernetesオブジェクトと一緒に`Table`リソースを構成します。
- 事前にプロビジョニングされた`${EKS_CLUSTER_AUTO_NAME}-carts-dynamo` IAMロールは`${EKS_CLUSTER_AUTO_NAME}-carts-*`テーブルにワイルドカードスコープされているため、同じロールがACKラボの`-carts-fastpath`テーブルとkroラボの`-carts-kro`テーブルの両方を変更なしでカバーします。

:::

このラボ全体を通じて、以下を行います：

1. kro機能が`ACTIVE`であり、`resourcegraphdefinitions.kro.run` CRDが存在することを確認します。
2. Namespace + ACK Table + ConfigMap + ServiceAccount + Deployment + Serviceを構成する`CartsStack` ResourceGraphDefinitionを適用します。
3. `CartsStack`インスタンスを適用し、kroが子リソースを順序通りに調整することを観察し、その後Pod Identityアソシエーションをバインドして、`carts` Podが新しいテーブルを読み書きできるようにします。

1つの`CartsStack`の適用により、次のグラフが生成されます：

```text
                適用するもの：
                CartsStack/carts-kro          (1つのCR、2つの必須フィールド)
                       │
                       ▼  kro reconcilerがRGDを展開
                       │
   ┌──────────┬────────┴──┬──────────┬─────────────┬──────────┐
   ▼          ▼           ▼          ▼             ▼          ▼
Namespace   Table     ConfigMap     SA        Deployment    Service
                        │                          │
                        ▼                          ▼
                   ACK DynamoDB                 Pod (carts-…)
                    controller                       │
                        │                            │ + aws eks create-pod-identity-association
                        ▼                            ▼
                AWS DynamoDB table          AWS_CONTAINER_CREDENTIALS
                (eks-workshop-…-carts-kro)   via Pod Identity Agent
```

:::info
kroはKubernetesリソースのみを調整します。AWS APIを直接呼び出すことはありません。上のグラフにあるAWS DynamoDBテーブルは、ACKラボのACKコントローラーによって作成されます。kroは`Table`リソースを作成することでそれを駆動します。
:::

## 機能の確認

機能が`ACTIVE`であることを確認します：

```bash
$ aws eks describe-capability \
  --cluster-name $EKS_CLUSTER_AUTO_NAME \
  --capability-name $EKS_CAP_KRO_CAPABILITY \
  --query 'capability.status' --output text
ACTIVE
```

次に、kroが登録したCRDを確認します。これは上記のRGD「設計図」タイプです：

```bash
$ kubectl api-resources --api-group=kro.run
NAME                       SHORTNAMES   APIVERSION         NAMESPACED   KIND
resourcegraphdefinitions   rgd          kro.run/v1alpha1   false        ResourceGraphDefinition
```

`NAMESPACED: false`に注意してください：RGDは**クラスタースコープ**です。なぜなら、設計図はクラスター全体で共有されるからです。それから作成するインスタンス（`CartsStack`リソース）は名前空間スコープです。なぜなら、各インスタンスは特定の名前空間内のリソースを所有するからです。機能が`ACTIVE`でRGD CRDが配置されているので、最初のRGDを定義する準備が整いました。

