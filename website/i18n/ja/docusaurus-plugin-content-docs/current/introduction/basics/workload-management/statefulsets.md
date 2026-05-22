---
title: StatefulSets
sidebar_position: 32
tmdTranslationSourceHash: f48100b6a8a52903afd4f3c1754ac19f
---

# StatefulSets

**StatefulSets**は、**安定したアイデンティティと永続ストレージ**を必要とするアプリケーションを管理します。Deploymentではポッドが交換可能であるのに対し、StatefulSet内の各ポッドは、そのライフサイクル全体を通じて**一意で予測可能なアイデンティティを保持**します。

ステートフルアプリケーションに対して、いくつかの重要な利点を提供します:
- **安定したアイデンティティの提供** - ポッドは予測可能な名前を取得します(mysql-0、mysql-1、mysql-2)
- **永続ストレージの有効化** - 各ポッドは独自の永続ボリュームを持つことができます
- **順序付けられた操作の保証** - ポッドは順次作成および削除されます
- **安定したネットワーキングの維持** - 各ポッドは同じネットワークアイデンティティを保持します
- **順序付きのローリングアップデートのサポート** - ポッドは一度に1つずつ更新されます

## StatefulSetのデプロイ

Catalogサービス用のMySQLデータベースをデプロイしましょう:

以下のYAMLは、Catalogサービス用にMySQLを実行するStatefulSetを作成し、永続ストレージと予測可能なPod名を持ちます。

::yaml{file="manifests/base-application/catalog/statefulset-mysql.yaml" paths="kind,metadata.name,spec.serviceName,spec.replicas" title="statefulset.yaml"}

1. `kind: StatefulSet`: StatefulSetコントローラーを作成します
2. `metadata.name`: StatefulSetの名前(catalog-mysql)
3. `spec.serviceName`: 安定したネットワークアイデンティティに必要(headless Serviceを作成します)
4. `spec.replicas`: 実行するポッドの数(この例では1)

データベースをデプロイします:
```bash
$ kubectl apply -k ~/environment/eks-workshop/base-application/catalog/
```

## StatefulSetの確認

StatefulSetのステータスを確認します:
```bash
$ kubectl get statefulset -n catalog
NAME            READY   AGE
catalog-mysql   1/1     2m
```

作成されたポッドを表示します:
```bash
$ kubectl get pods -n catalog
NAME              READY   STATUS    RESTARTS   AGE
catalog-mysql-0   1/1     Running   0          2m
```
> 数字のサフィックスを持つ予測可能なポッド名に注目してください

StatefulSetの詳細情報を取得します:
```bash
$ kubectl describe statefulset -n catalog catalog-mysql
```

サフィックス(`-0`、`-1`など)により、ストレージとネットワークの目的で各ポッドを個別に追跡できます。

## StatefulSetのスケーリング

3つのレプリカにスケールアップします:
```bash
$ kubectl scale statefulset -n catalog catalog-mysql --replicas=3
$ kubectl get pods -n catalog
NAME              READY   STATUS    RESTARTS   AGE
catalog-mysql-0   1/1     Running   0          5m
catalog-mysql-1   0/1     Pending   0          10s
catalog-mysql-1   1/1     Running   0          30s
catalog-mysql-2   0/1     Pending   0          5s
catalog-mysql-2   1/1     Running   0          25s
```
ポッドが順番に1つずつ作成されるのがわかります

スケールダウンします:
```bash
$ kubectl scale statefulset -n catalog catalog-mysql --replicas=1
```

ポッドは逆順に削除されます(2、次に1、0を保持)、安定性を確保します。

Kubernetesはまた、スケールアップまたはスケールダウンした場合でも、**各ポッドが永続ボリュームを保持する**ことを保証します。

## StatefulSets vs Deployments
| 機能           | StatefulSet                   | Deployment        |
| ----------------- | ----------------------------- | ----------------- |
| Pod名         | 安定(`mysql-0`、`mysql-1`) | ランダム            |
| ストレージ           | ポッドごとに永続            | 通常は一時的 |
| 作成/削除 | 順序付き                       | 任意の順序         |
| ネットワークアイデンティティ  | 安定                        | 動的           |
| ユースケース          | データベース、メッセージキュー     | ステートレスアプリ    |

:::info
StatefulSetは、永続的なアイデンティティ、安定したネットワーキング、順序付けられた操作を必要とするアプリケーションに最適です。
:::

## 覚えておくべきポイント

* StatefulSetは各ポッドに安定した一意のアイデンティティを提供します
* データベース、メッセージキュー、クラスター化されたアプリケーションに最適です
* 各ポッドは再起動後も存続する独自の永続ストレージを持つことができます
* 操作は順序通りに行われます - 作成(0→1→2)と削除(2→1→0)
* ポッド名は予測可能で変更されません
* アプリケーションがアイデンティティ、安定性、永続性を必要とする場合は常にStatefulSetを使用してください。

