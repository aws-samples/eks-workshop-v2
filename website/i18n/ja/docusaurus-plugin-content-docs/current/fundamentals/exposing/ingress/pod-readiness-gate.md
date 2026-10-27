---
title: "Pod readiness gate"
sidebar_position: 40
tmdTranslationSourceHash: '4335bae08c696f33d1e98327c19ef1f5'
---

Deployment がロールアウトされると、Kubernetes は新しい Pod が `Ready` になった時点で、すぐに古い Pod を終了します。Pod の前段に ALB がある場合、`Ready` はコンテナ自身のプローブに合格したことしか意味しません。新しい Pod は、ターゲットグループに登録され、ALB のヘルスチェックにも合格する必要があります。レプリカ数が少ない場合、すべてのターゲットが `initial` のままか、すでに `draining` になっている瞬間が発生し、ALB がエラーを返すことがあります。

AWS Load Balancer Controller は、[Pod readiness gates](https://kubernetes-sigs.github.io/aws-load-balancer-controller/latest/deploy/pod_readiness_gate/)を使用してこの問題を解決します。コントローラーはターゲットグループの背後にある各 Pod に readiness gate を追加し、対応するターゲットが ALB で `healthy` になった時点で初めて `True` に設定します。これにより、ローリングアップデートでは、新しい Pod が ALB で healthy になるのを待ってから古い Pod を終了します。

:::info
Readiness gate は `target-type: ip` でのみ動作します。このラボの Ingress はこれを使用しています。`target-type: instance` の場合、ターゲットはノードであるため、ALB は個々の Pod を認識できません。
:::

wide 出力の `READINESS GATES` 列を見ると、現在 `ui` Pod には readiness gate がないことがわかります。

```bash
$ kubectl -n ui get pods -o wide
NAME                  READY   STATUS    RESTARTS   AGE     IP             NODE                                          NOMINATED NODE   READINESS GATES
ui-5989474687-swm27   1/1     Running   0          2m24s   10.42.181.33   ip-10-42-176-252.us-west-2.compute.internal   <none>           <none>
```

readiness gate がない場合のロールアウトの様子を確認するため、Deployment を再起動します。

```bash timeout=180
$ kubectl -n ui rollout restart deployment ui
deployment.apps/ui restarted
$ kubectl -n ui rollout status deployment ui --timeout=120s
deployment "ui" successfully rolled out
```

新しい Pod が `Ready` になるとすぐにロールアウトが完了し、古い Pod はすでに終了処理に入っています。すぐに `ui` ロードバランサーのターゲットグループを確認してください。

```bash
$ ALB_ARN=$(aws elbv2 describe-load-balancers --query 'LoadBalancers[?contains(LoadBalancerName, `k8s-ui-ui`) == `true`].LoadBalancerArn' | jq -r '.[0]')
$ TARGET_GROUP_ARN=$(aws elbv2 describe-target-groups --load-balancer-arn $ALB_ARN | jq -r '.TargetGroups[0].TargetGroupArn')
$ aws elbv2 describe-target-health --target-group-arn $TARGET_GROUP_ARN --query 'TargetHealthDescriptions[].TargetHealth'
[
    {
        "State": "initial",
        "Reason": "Elb.RegistrationInProgress",
        "Description": "Target registration is in progress"
    },
    {
        "State": "draining",
        "Reason": "Target.DeregistrationInProgress",
        "Description": "Target deregistration is in progress"
    }
]
```

タイミングによっては、新しいターゲットのみが表示されたり、すでに `healthy` になっていたりする場合があります。`healthy` なターゲットが存在しない間は、アプリケーションへのリクエストが HTTP 502 または 503 エラーで失敗します。

Readiness gate の注入は Namespace 単位で有効にします。`ui` Namespace にラベルを付けて、コントローラーの webhook が新しい Pod に readiness gate を追加するようにします。

```bash
$ kubectl label namespace ui elbv2.k8s.aws/pod-readiness-gate-inject=enabled
namespace/ui labeled
```

Readiness gate は Pod の作成時にのみ追加されるため、Deployment をもう一度再起動します。今回は、新しい Pod が ALB で healthy になるまでロールアウトが待機します。

```bash timeout=300 hook=readiness-gate hookTimeout=300
$ kubectl -n ui rollout restart deployment ui
deployment.apps/ui restarted
$ kubectl -n ui rollout status deployment ui --timeout=240s
deployment "ui" successfully rolled out
```

ロールアウトの進行中は、新しい Pod の readiness gates は `0/1` と表示され、古い Pod がトラフィックを処理し続けます。ターゲットが `healthy` になると gate は `1/1` に変わり、その後に初めて古い Pod が終了されます。

```bash test=false
$ kubectl -n ui get pods -o wide
NAME                  READY   STATUS    RESTARTS   AGE    IP              NODE                                          NOMINATED NODE   READINESS GATES
ui-886bb64b8-cxmsx    1/1     Running   0          112s   10.42.158.114   ip-10-42-137-174.us-west-2.compute.internal   <none>           1/1
ui-6fd4c6cc49-f8tqm   1/1     Running   0          3s     10.42.181.33    ip-10-42-176-252.us-west-2.compute.internal   <none>           0/1
```

Readiness gate は、タイプが `target-health.elbv2.k8s.aws/` で始まり、その後にターゲットグループバインディングの名前が続く Pod condition です。

```bash
$ kubectl -n ui get pods -l app.kubernetes.io/name=ui \
  -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{range .status.conditions[*]}{"  "}{.type}={.status}{"\n"}{end}{end}'
ui-6fd4c6cc49-f8tqm
  target-health.elbv2.k8s.aws/k8s-ui-ui-b21a807597=True
  PodReadyToStartContainers=True
  Initialized=True
  Ready=True
  ContainersReady=True
  PodScheduled=True
```

Pod は、この condition が `True` になって初めて `Ready` になります。そのため、`ui` アプリケーションはロールアウト中ずっと到達可能な状態を維持します。

