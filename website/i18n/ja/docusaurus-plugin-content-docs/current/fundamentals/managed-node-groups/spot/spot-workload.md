---
title: "Spotインスタンス上でのワークロードの実行"
sidebar_position: 30
kiteTranslationSourceHash: 385939ef1c0b700b043d44ac206d57e2
---

次に、サンプルの小売店アプリケーションを変更して、カタログコンポーネントを新しく作成したSpotインスタンス上で実行しましょう。そのために、Kustomizeを使用して`catalog`デプロイメントにパッチを適用し、`nodeSelector`フィールドを`eks.amazonaws.com/capacityType: SPOT`で追加します。

```kustomization
modules/fundamentals/mng/spot/deployment/deployment.yaml
Deployment/catalog
```

以下のコマンドでKustomizeパッチを適用します。

```bash
$ kubectl apply -k ~/environment/eks-workshop/modules/fundamentals/mng/spot/deployment

namespace/catalog unchanged
serviceaccount/catalog unchanged
configmap/catalog unchanged
secret/catalog-db unchanged
service/catalog unchanged
service/catalog-mysql unchanged
deployment.apps/catalog configured
statefulset.apps/catalog-mysql unchanged
```

以下のコマンドでアプリケーションが正常にデプロイされたことを確認します。

```bash
$ kubectl rollout status deployment/catalog -n catalog --timeout=5m
```

最後に、catalogポッドがSpotインスタンス上で実行されていることを確認しましょう。以下の2つのコマンドを実行します。

```bash
$ kubectl get pods -l app.kubernetes.io/component=service -n catalog -o wide

NAME                       READY   STATUS    RESTARTS   AGE     IP              NODE
catalog-6bf46b9654-9klmd   1/1     Running   0          7m13s   10.42.118.208   ip-10-42-99-254.us-east-2.compute.internal
$ kubectl get nodes -l eks.amazonaws.com/capacityType=SPOT

NAME                                          STATUS   ROLES    AGE   VERSION
ip-10-42-139-140.us-east-2.compute.internal   Ready    <none>   16m   vVAR::KUBERNETES_NODE_VERSION
ip-10-42-99-254.us-east-2.compute.internal    Ready    <none>   16m   vVAR::KUBERNETES_NODE_VERSION

```

最初のコマンドでは、catalogポッドが`ip-10-42-99-254.us-east-2.compute.internal`ノード上で実行されていることがわかります。2番目のコマンドの出力と照合することで、これがSpotインスタンスであることを確認できます。

このラボでは、Spotインスタンスを作成するマネージドノードグループをデプロイし、次に`catalog`デプロイメントを変更して、新しく作成されたSpotインスタンス上で実行するようにしました。このプロセスに従って、上記のKustomizationパッチで指定されているように`nodeSelector`パラメータを追加することで、クラスター内で実行されている任意のデプロイメントを変更できます。

