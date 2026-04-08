---
title: "ハイブリッドノードへのトラフィックのルーティング"
sidebar_position: 10
sidebar_custom_props: { "module": false }
weight: 25 # used by test framework
tmdTranslationSourceHash: 6788556a7a4a9439c02c3c9fc4d89018
---

これで、ハイブリッドノードインスタンスがクラスターに接続されたので、
以下の`Deployment`と`Ingress`マニフェストを使用してサンプルワークロードをデプロイできます：

::yaml{file="manifests/modules/networking/eks-hybrid-nodes/kustomize/deployment.yaml" paths="spec.template.spec.affinity.nodeAffinity"}

1. `nodeAffinity`ルールを使用して、Kubernetesスケジューラーに`eks.amazonaws.com/compute-type=hybrid`ラベルと値を持つクラスターノードを*優先*するように指示します。

::yaml{file="manifests/modules/networking/eks-hybrid-nodes/kustomize/ingress.yaml" paths="spec.ingressClassName"}

1. `ingress`リソースは、AWSロードバランサー（ALB）を構成してワークロードポッドにトラフィックをルーティングします。

ワークロードをデプロイしましょう：

```bash
$ kubectl apply -k ~/environment/eks-workshop/modules/networking/eks-hybrid-nodes/kustomize
namespace/nginx-remote created
service/nginx created
deployment.apps/nginx created
ingress.networking.k8s.io/nginx created
```

ポッドが正常にハイブリッドノードにスケジュールされたことを確認しましょう：

```bash
$ kubectl get pods -n nginx-remote -o=custom-columns='NAME:.metadata.name,NODE:.spec.nodeName'
NAME                     NODE
nginx-787d665f9b-2bcms   mi-027504c0970455ba5
nginx-787d665f9b-hgrnp   mi-027504c0970455ba5
nginx-787d665f9b-kv4x9   mi-027504c0970455ba5
```

素晴らしい！予想通り、3つのnginxポッドはハイブリッドノード上で実行されています。

:::tip
ALBのプロビジョニングには数分かかる場合があります。続行する前に、次のコマンドでロードバランサーのプロビジョニングが完了したことを確認してください：

```bash
$ aws elbv2 describe-load-balancers --query 'LoadBalancers[?contains(LoadBalancerName, `k8s-nginxrem-nginx`) == `true`]' --query 'LoadBalancers[0].State.Code'
"active"
```

:::

ALBがアクティブになったら、IngressのAssociatedの`Address`を確認してALBのURLを取得できます：

```bash
$ export ADDRESS=$(kubectl get ingress -n nginx-remote nginx -o jsonpath="{.status.loadBalancer.ingress[*].hostname}{'\n'}") && echo $ADDRESS
k8s-nginxrem-nginx-03efa1e84c-012345678.us-west-2.elb.amazonaws.com
```

ALB URLを使って、コマンドラインからアクセスするか、ウェブブラウザにアドレスを入力してデプロイメントにアクセスできます。ALBはIngressルールに基づいて適切なポッドにトラフィックをルーティングします。

```bash test=false
$ curl $ADDRESS
Connected to 10.53.0.5 on mi-027504c0970455ba5
```

curlまたはブラウザからの出力には、`mi-`プレフィックスを持つハイブリッドノード上で実行されているロードバランサーからのリクエストを受信するポッドの`10.53.0.X`のIPアドレスが表示されます。

curlコマンドを数回再実行するか、ブラウザを更新して、各リクエストでポッドのIPが変化し、ノード名は同じままであることに注目してください。これは、すべてのポッドが同じリモートノード上でスケジュールされているためです。

```bash test=false
$ curl -s $ADDRESS
Connected to 10.53.0.5 on mi-027504c0970455ba5
$ curl -s $ADDRESS
Connected to 10.53.0.11 on mi-027504c0970455ba5
$ curl -s $ADDRESS
Connected to 10.53.0.84 on mi-027504c0970455ba5
```

ハイブリッドノードへのワークロードのデプロイ、ALBを通じてアクセスできるよう構成、およびトラフィックがリモートノードで実行されているポッドに適切にルーティングされていることを確認することに成功しました。

EKSハイブリッドノードでさらに多くのユースケースを探索する前に、少しクリーンアップをしましょう。

```bash timeout=300 wait=30
$ kubectl delete -k ~/environment/eks-workshop/modules/networking/eks-hybrid-nodes/kustomize --ignore-not-found=true
```
