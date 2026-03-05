---
title: "kroによるリソースの作成"
sidebar_position: 5
tmdTranslationSourceHash: b9394e7175a82507b6f33e051b9ffbe3
---

kroをインストールしたので、WebApplication ResourceGraphDefinitionsを使用して**Carts**コンポーネントをデプロイします。まず、再利用可能なWebApplication APIを定義するResourceGraphDefinitionテンプレートを確認しましょう：

<details>
  <summary>RGDマニフェストの全容を表示</summary>

::yaml{file="manifests/modules/automation/controlplanes/kro/rgds/webapp-rgd.yaml"}

</details>

このResourceGraphDefinitionは、以下のデプロイの複雑さを抽象化するカスタム`WebApplication` APIを作成します：

- ServiceAccount
- ConfigMap
- Deployment
- Service
- Ingress（オプション）

スキーマは以下に示すように、アプリケーションイメージ、レプリカ数、環境変数、ヘルスチェック設定などの主要パラメータをカスタマイズできるようにしながら、適切なデフォルト値を提供します：

::yaml{file="manifests/modules/automation/controlplanes/kro/rgds/webapp-rgd.yaml" zoomPath="spec.schema.spec" zoomBefore="0"}

:::info
スキーマがどのようにデフォルト値と型定義を使用して、Kubernetesの複雑さを隠し、開発者に優しいAPIを作成しているかに注目してください。
:::

このWebApplication ResourceGraphDefinitionを使用して、インメモリデータベースを使用する**Carts**コンポーネントのインスタンスを作成します。まず、既存のcartsデプロイメントをクリーンアップしましょう：

```bash
$ kubectl delete all --all -n carts
pod "carts-68d496fff8-9lcpc" deleted
pod "carts-dynamodb-995f7768c-wtsbr" deleted
service "carts" deleted
service "carts-dynamodb" deleted
deployment.apps "carts" deleted
deployment.apps "carts-dynamodb" deleted
```

次に、WebApplication APIを登録するためにResourceGraphDefinitionを適用します：

```bash wait=10
$ kubectl apply -f ~/environment/eks-workshop/modules/automation/controlplanes/kro/rgds/webapp-rgd.yaml
resourcegraphdefinition.kro.run/web-application created
```

これによりWebApplication APIが登録されます。kroは自動的にRGDスキーマに基づいてカスタムリソース定義（CRD）を作成します。CRDを確認しましょう：

```bash
$ kubectl get crd webapplications.kro.run
NAME                       CREATED AT
webapplications.kro.run    2024-01-15T10:30:00Z
```

次に、WebApplication APIを使用して**Carts**コンポーネントのインスタンスを作成する`carts.yaml`ファイルを確認しましょう：

::yaml{file="manifests/modules/automation/controlplanes/kro/app/carts.yaml" paths="kind,metadata,spec.appName,spec.replicas,spec.image,spec.port,spec.env,spec.service"}

1. RGDによって作成されたカスタムWebApplication APIを使用します
2. `carts`名前空間に`carts`という名前のリソースを作成します
3. リソースの命名のためにアプリケーション名を指定します
4. 単一レプリカを設定します
5. 小売店のカートサービスコンテナイメージを使用します
6. ポート8080でアプリケーションを公開します
7. インメモリ永続化モードのための環境変数を構成します
8. Kubernetes Serviceリソースを有効にします

アプリケーションをデプロイしましょう：

```bash wait=30
$ kubectl apply -f ~/environment/eks-workshop/modules/automation/controlplanes/kro/app/carts.yaml
webapplication.kro.run/carts created
```

kroはこのカスタムリソースを処理し、すべての基礎となるKubernetesリソースを作成します。カスタムリソースが作成されたことを確認しましょう：

```bash
$ kubectl get webapplication -n carts
NAME    STATE         SYNCED   AGE
carts   IN_PROGRESS   False    16s
```

インスタンスが「同期済み」状態に達するまで待ちましょう：

```bash
$ kubectl wait -o yaml webapplication/carts -n carts \
  --for=condition=InstanceSynced=True --timeout=120s
```

次に、RGDのコンポーネントが実行中であることを確認します：

```bash
$ kubectl get all -n carts
NAME                         READY   STATUS    RESTARTS   AGE
pod/carts-7d58cfb7c9-xyz12   1/1     Running   0          30s

NAME            TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
service/carts   ClusterIP   172.20.123.45   <none>        80/TCP    30s

NAME                    READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/carts   1/1     1            1           30s

NAME                               DESIRED   CURRENT   READY   AGE
replicaset.apps/carts-7d58cfb7c9   1         1         1       30s
```

kroは**Carts**コンポーネントに必要なすべてのKubernetesリソースのデプロイを単一のユニットとして正常にオーケストレーションしました。kroを使用することで、通常は複数のYAMLファイルの適用が必要となるものを、単一の宣言的なAPI呼び出しに変換しました。これは複雑なリソースオーケストレーションを簡素化するkroの力を示しています。

次のセクションでは、現在cartsが使用しているインメモリデータベースをAmazon DynamoDBテーブルに置き換えます。
