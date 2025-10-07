---
title: Scheduling on Fargate
sidebar_position: 12
kiteTranslationSourceHash: 8326843c164fc6ba07cea47a038eb4b5
---

なぜ `checkout` サービスがすでに Fargate で実行されていないのでしょうか？そのラベルを確認してみましょう：

```bash
$ kubectl get pod -n checkout -l app.kubernetes.io/component=service -o json | jq '.items[0].metadata.labels'
```

私たちの Pod には `fargate=yes` というラベルが不足しているようです。それを修正するために、プロファイルが Fargate で Pod をスケジュールするために必要なラベルを含めるようにそのサービスのデプロイメントを更新しましょう。

```kustomization
modules/fundamentals/fargate/enabling/deployment.yaml
Deployment/checkout
```

クラスターに kustomization を適用します：

```bash timeout=220 hook=enabling
$ kubectl apply -k ~/environment/eks-workshop/modules/fundamentals/fargate/enabling
[...]
$ kubectl rollout status -n checkout deployment/checkout --timeout=200s
```

これにより、`checkout` サービスの Pod 仕様が更新され、新しいデプロイメントが開始され、すべての Pod が置き換えられます。新しい Pod がスケジュールされると、Fargate スケジューラーが kustomization によって適用された新しいラベルを私たちのターゲットプロファイルと一致させ、Pod が Fargate によって管理されるキャパシティでスケジュールされるよう介入します。

うまくいったかどうかを確認するにはどうすればよいでしょうか？作成された新しい Pod を詳細に調べて、`Events` セクションを見てみましょう：

```bash
$ kubectl describe pod -n checkout -l fargate=yes
[...]
Events:
  Type     Reason           Age    From               Message
  ----     ------           ----   ----               -------
  Warning  LoggingDisabled  10m    fargate-scheduler  Disabled logging because aws-logging configmap was not found. configmap "aws-logging" not found
  Normal   Scheduled        9m48s  fargate-scheduler  Successfully assigned checkout/checkout-78fbb666b-fftl5 to fargate-ip-10-42-11-96.us-west-2.compute.internal
  Normal   Pulling          9m48s  kubelet            Pulling image "public.ecr.aws/aws-containers/retail-store-sample-checkout:0.4.0"
  Normal   Pulled           9m5s   kubelet            Successfully pulled image "public.ecr.aws/aws-containers/retail-store-sample-checkout:0.4.0" in 43.258137629s
  Normal   Created          9m5s   kubelet            Created container checkout
  Normal   Started          9m4s   kubelet            Started container checkout
```

`fargate-scheduler` からのイベントは何が起こったかについて洞察を与えてくれます。この段階でのラボで主に注目しているのは、理由が `Scheduled` のイベントです。そのエントリを詳しく調査すると、この Pod のためにプロビジョニングされた Fargate インスタンスの名前がわかります。上記の例では、これは `fargate-ip-10-42-11-96.us-west-2.compute.internal` です。

`kubectl` からこのノードを検査して、この Pod 用にプロビジョニングされたコンピュートに関する追加情報を得ることができます：

```bash
$ NODE_NAME=$(kubectl get pod -n checkout -l app.kubernetes.io/component=service -o json | jq -r '.items[0].spec.nodeName')
$ kubectl describe node $NODE_NAME
Name:               fargate-ip-10-42-11-96.us-west-2.compute.internal
Roles:              <none>
Labels:             beta.kubernetes.io/arch=amd64
                    beta.kubernetes.io/os=linux
                    eks.amazonaws.com/compute-type=fargate
                    failure-domain.beta.kubernetes.io/region=us-west-2
                    failure-domain.beta.kubernetes.io/zone=us-west-2b
                    kubernetes.io/arch=amd64
                    kubernetes.io/hostname=ip-10-42-11-96.us-west-2.compute.internal
                    kubernetes.io/os=linux
                    topology.kubernetes.io/region=us-west-2
                    topology.kubernetes.io/zone=us-west-2b
[...]
```

これにより、基盤となるコンピュートインスタンスの性質についていくつかの洞察が得られます：

- ラベル `eks.amazonaws.com/compute-type` は、Fargate インスタンスがプロビジョニングされたことを確認します
- もう一つのラベル `topology.kubernetes.io/zone` は、pod が実行されているアベイラビリティーゾーンを指定します
- `System Info` セクション（上記には表示されていません）では、インスタンスが Amazon Linux 2 を実行していることがわかります。また、`container`、`kubelet`、`kube-proxy` などのシステムコンポーネントのバージョン情報も確認できます

