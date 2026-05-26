---
title: 最初のコンポーネントのデプロイ
sidebar_position: 40
tmdTranslationSourceHash: '0dbec28f9d8a26b4d0a8e6cd338727a4'
---

サンプルアプリケーションは、Kustomize で簡単に適用できるように構成された Kubernetes マニフェストのセットで構成されています。Kustomize はオープンソースのツールであり、`kubectl` CLI のネイティブ機能としても提供されています。このワークショップでは、Kustomize を使用して Kubernetes マニフェストに変更を適用し、YAML を手動で編集することなくマニフェストファイルの変更を理解しやすくします。このワークショップのさまざまなモジュールを進めていく中で、Kustomize を使用してオーバーレイとパッチを段階的に適用していきます。

サンプルアプリケーションと、このワークショップのモジュールの YAML マニフェストを参照する最も簡単な方法は、IDE のファイルブラウザを使用することです。

![IDE files](/img/fastpaths/getting-started/ide-initial.webp)

`eks-workshop` を展開し、次に `base-application` の項目を展開すると、サンプルアプリケーションの初期状態を構成するマニフェストを参照できます。

![IDE files base](/img/fastpaths/getting-started/ide-base.webp)

この構造は、**サンプルアプリケーション**セクションで概説された各アプリケーションコンポーネントのディレクトリで構成されています。

`modules` ディレクトリには、後続のラボ演習全体でクラスタに適用するマニフェストのセットが含まれています。

![IDE files modules](/img/fastpaths/getting-started/ide-modules.webp)

何かを行う前に、EKS クラスタの現在の Namespace を確認しましょう。

```bash
$ kubectl get namespaces
NAME              STATUS   AGE
default           Active   30h
kube-node-lease   Active   30h
kube-public       Active   30h
kube-system       Active   30h
```

リストされているすべてのエントリは、システムコンポーネントの Namespace です。[Kubernetes labels](https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/) を使用して、作成した Namespace のみにフィルタリングします。

```bash
$ kubectl get namespaces -l app.kubernetes.io/created-by=eks-workshop
No resources found
```

最初に行うことは、catalog コンポーネントを単独でデプロイすることです。このコンポーネントのマニフェストは `~/environment/eks-workshop/base-application/catalog` にあります。

```bash
$ ls ~/environment/eks-workshop/base-application/catalog
configMap.yaml
deployment.yaml
kustomization.yaml
namespace.yaml
secrets.yaml
service-mysql.yaml
service.yaml
serviceAccount.yaml
statefulset-mysql.yaml
```

これらのマニフェストには、catalog API の望ましい状態を表現する Deployment が含まれています。

::yaml{file="manifests/base-application/catalog/deployment.yaml" paths="spec.replicas,spec.template.metadata.labels,spec.template.spec.containers.0.image,spec.template.spec.containers.0.ports,spec.template.spec.containers.0.livenessProbe,spec.template.spec.containers.0.resources"}

1. 単一のレプリカを実行します
2. 他のリソースが参照できるように、Pod にラベルを適用します
3. `public.ecr.aws/aws-containers/retail-store-sample-catalog` コンテナイメージを使用します
4. `http` という名前のポート 8080 でコンテナを公開します
5. `/health` パスに対して [probes/healthchecks](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/) を実行します
6. Kubernetes スケジューラが十分な利用可能リソースを持つノードに配置できるように、特定の量の CPU とメモリを[リクエスト](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/)します

マニフェストには、他のコンポーネントが catalog API にアクセスするために使用する Service も含まれています。

::yaml{file="manifests/base-application/catalog/service.yaml" paths="spec.ports,spec.selector"}

1. ポート 80 で自身を公開し、Deployment によって公開される `http` ポートをターゲットにします。これはポート 8080 に変換されます
2. 上記の Deployment で表現したものと一致するラベルを使用して catalog Pod を選択します

catalog コンポーネントを作成しましょう。

```bash
$ kubectl apply -k ~/environment/eks-workshop/base-application/catalog
namespace/catalog created
serviceaccount/catalog created
configmap/catalog created
secret/catalog-db created
service/catalog created
service/catalog-mysql created
deployment.apps/catalog created
statefulset.apps/catalog-mysql created
```

:::info EKS Auto Mode のコンピュートプロビジョニング
Amazon EKS Auto Mode にワークロードをデプロイすると、クラスタは Pod を実行するための EC2 インスタンスを自動的にプロビジョニングします。このプロセスをリアルタイムで観察してみましょう。
:::



```bash
$ kubectl get pod -n catalog
NAME                      READY   STATUS    RESTARTS      AGE
catalog-5fdcc8c65-jkg9f   1/1     Running   2 (87s ago)   2m6s
catalog-mysql-0           1/1     Running   0             2m5s
```

<!-- `catalog` Pod のステータスが `CrashLoopBackOff` と表示されている場合、起動する前に `catalog-mysql` Pod に接続できる必要があります。Kubernetes はこれが当てはまるまで再起動を続けます。その場合、[kubectl wait](https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#wait) を使用して、Ready 状態になるまで特定の Pod を監視できます。-->

Pod がまだ準備できていない場合は、[kubectl wait](https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#wait) を使用して準備ができるまで待つことができます。

```bash timeout=200
$ kubectl wait --for=condition=Ready pods --all -n catalog --timeout=180s
```

Pod が実行されているので、[ログを確認](https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#logs)できます。例えば catalog API の場合は次のようになります。

:::tip
[kubectl logs の出力を「フォロー」する](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)には、コマンドに '-f' オプションを使用します。（出力のフォローを停止するには CTRL-C を使用します）
:::

```bash
$ kubectl logs -n catalog deployment/catalog
```

Kubernetes では、catalog Pod の数を水平方向に簡単にスケーリングすることもできます。

```bash
$ kubectl scale -n catalog --replicas 3 deployment/catalog
deployment.apps/catalog scaled
$ kubectl wait --for=condition=Ready pods --all -n catalog --timeout=180s
```

:::info Auto Mode の自動スケーリング
EKS Auto Mode は、ワークロードの需要に合わせてコンピュート容量を自動的にスケーリングします。現在のノードが処理できる以上のレプリカにスケーリングすると、Auto Mode は追加のノードを自動的にプロビジョニングします。クラスタは Pod のリソース要件に基づいて、ノードの配置と容量を継続的に最適化します。
:::

適用したマニフェストは、クラスタ内の他のコンポーネントが接続するために使用できる、アプリケーションと MySQL Pod のそれぞれの Service も作成します。

```bash
$ kubectl get svc -n catalog
NAME            TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE
catalog         ClusterIP   172.20.83.84     <none>        80/TCP     2m48s
catalog-mysql   ClusterIP   172.20.181.252   <none>        3306/TCP   2m48s
```

これらの Service はクラスタの内部にあるため、インターネットや VPC からアクセスすることはできません。ただし、[exec](https://kubernetes.io/docs/tasks/debug/debug-application/get-shell-running-container/) を使用して EKS クラスタ内の既存の Pod にアクセスし、catalog API が動作していることを確認できます。

```bash timeout=180
$ kubectl -n catalog exec -i \
  deployment/catalog -- curl catalog.catalog.svc/catalog/products | jq .
```

製品情報を含む JSON ペイロードが返されるはずです。おめでとうございます。Kubernetes と EKS を使用して最初のマイクロサービスをデプロイしました！

