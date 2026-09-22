---
title: "IPモード"
sidebar_position: 40
tmdTranslationSourceHash: '3b12b3e9dd53801847aa273070a1b9bc'
---

前述のように、作成したNLBは「インスタンスモード」で動作しています。インスタンスターゲットモードはAWS EC2インスタンス上で実行されているPodをサポートしています。このモードでは、AWS NLBはインスタンスにトラフィックを送信し、個々のワーカーノード上の`kube-proxy`がKubernetesクラスター内の1つ以上のワーカーノードを介してPodにトラフィックを転送します。

AWS Load Balancer Controllerは、「IPモード」で動作するNLBの作成もサポートしています。このモードでは、AWS NLBはKubernetesクラスター内のワーカーノードを経由する余分なネットワークホップを排除して、Serviceの背後にあるKubernetes Podに直接トラフィックを送信します。IPターゲットモードは、AWS EC2インスタンスとAWS Fargateの両方で実行されているPodをサポートしています。

![NLBターゲットモードの並列比較：インスタンスモードではターゲットグループがNodePort上のEC2インスタンスを登録し、kube-proxyがui Podへの接続を中継します。一方、IPモードではターゲットグループがPod IPアドレスを登録し、ロードバランサーがui Podに直接接続します](/docs/fundamentals/exposing/loadbalancer/ip-mode.webp)

上の図は2つのモードを並べて比較しています。`Service`、Network Load Balancer、およびポート80のTCPリスナーは両方で同一です。変更されるのはロードバランサーのターゲットグループに登録される対象だけです。

**インスタンスモード**では、ターゲットグループはKubernetesが`Service`に割り当てたNodePort上のEC2ワーカーノードを登録します。したがって、接続はまずノードに到達し、そのノード上の`kube-proxy`がui Podに中継します。接続を受信したノードがui Podを実行していない場合、`kube-proxy`は実行しているノードに転送し、2つ目のネットワークホップが追加されます。

**IPモード**では、ターゲットグループはPod IPアドレスを登録するため、ロードバランサーはui Podに直接接続を開き、`kube-proxy`はデータパスに含まれません。これはAmazon VPC CNIがすべてのPodにファーストクラスでルーティング可能なVPC IPアドレスを付与するため機能します。

NLBをIPターゲットモードで構成したい理由はいくつかあります：

1. 受信接続のためのより効率的なネットワークパスを作成し、EC2ワーカーノード上の`kube-proxy`をバイパスします
2. `externalTrafficPolicy`やその様々な構成オプションのトレードオフなどの側面を考慮する必要がなくなります
3. アプリケーションがEC2ではなくFargateで実行されている場合

### NLBの再構成

NLBをIPモードを使用するように再構成し、インフラストラクチャにどのような影響があるかを見てみましょう。

これはServiceを再構成するために適用するパッチです：

```kustomization
modules/exposing/load-balancer/ip-mode/nlb.yaml
Service/ui-nlb
```

kustomizeでマニフェストを適用します：

```bash
$ kubectl kustomize ~/environment/eks-workshop/modules/exposing/load-balancer/ip-mode | envsubst | kubectl apply -f -
```

ロードバランサーの構成が更新されるまで数分かかります。以下のコマンドを実行して、アノテーションが更新されたことを確認します：

```bash
$ kubectl describe service/ui-nlb -n ui
...
Annotations:              service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: ip
...
```

以前と同じURLを使用してアプリケーションにアクセスできるはずですが、NLBは現在IPモードを使用してアプリケーションを公開しています。

```bash
$ NLB_ARN=$(aws elbv2 describe-load-balancers --query 'LoadBalancers[?contains(LoadBalancerName, `k8s-ui-uinlb`) == `true`].LoadBalancerArn' | jq -r '.[0]')
$ TARGET_GROUP_ARN=$(aws elbv2 describe-target-groups --load-balancer-arn $NLB_ARN | jq -r '.TargetGroups[0].TargetGroupArn')
$ aws elbv2 describe-target-health --target-group-arn $TARGET_GROUP_ARN
{
    "TargetHealthDescriptions": [
        {
            "Target": {
                "Id": "10.42.180.183",
                "Port": 8080,
                "AvailabilityZone": "us-west-2a"
            },
            "HealthCheckPort": "8080",
            "TargetHealth": {
                "State": "initial",
                "Reason": "Elb.RegistrationInProgress",
                "Description": "Target registration is in progress"
            }
        }
    ]
}
```

前のセクションで観察した3つのターゲットから、たった1つのターゲットに変わっていることに注目してください。なぜでしょうか？EKSクラスター内のEC2インスタンスを登録する代わりに、ロードバランサーコントローラーは現在個々のPodを登録し、トラフィックを直接送信しています。これはAWS VPC CNIとPodそれぞれがファーストクラスのVPC IPアドレスを持つという事実を活用しています。

uiコンポーネントを3つのレプリカにスケールアップして、何が起こるか見てみましょう：

```bash
$ kubectl scale -n ui deployment/ui --replicas=3
$ kubectl wait --for=condition=Ready pod -n ui -l app.kubernetes.io/name=ui --timeout=60s
```

ロードバランサーのターゲットを再度確認します：

```bash
$ NLB_ARN=$(aws elbv2 describe-load-balancers --query 'LoadBalancers[?contains(LoadBalancerName, `k8s-ui-uinlb`) == `true`].LoadBalancerArn' | jq -r '.[0]')
$ TARGET_GROUP_ARN=$(aws elbv2 describe-target-groups --load-balancer-arn $NLB_ARN | jq -r '.TargetGroups[0].TargetGroupArn')
$ aws elbv2 describe-target-health --target-group-arn $TARGET_GROUP_ARN
{
    "TargetHealthDescriptions": [
        {
            "Target": {
                "Id": "10.42.180.181",
                "Port": 8080,
                "AvailabilityZone": "us-west-2c"
            },
            "HealthCheckPort": "8080",
            "TargetHealth": {
                "State": "initial",
                "Reason": "Elb.RegistrationInProgress",
                "Description": "Target registration is in progress"
            }
        },
        {
            "Target": {
                "Id": "10.42.140.129",
                "Port": 8080,
                "AvailabilityZone": "us-west-2a"
            },
            "HealthCheckPort": "8080",
            "TargetHealth": {
                "State": "healthy"
            }
        },
        {
            "Target": {
                "Id": "10.42.105.38",
                "Port": 8080,
                "AvailabilityZone": "us-west-2a"
            },
            "HealthCheckPort": "8080",
            "TargetHealth": {
                "State": "initial",
                "Reason": "Elb.RegistrationInProgress",
                "Description": "Target registration is in progress"
            }
        }
    ]
}
```

予想通り、ui Deploymentのレプリカ数に一致する3つのターゲットが表示されるようになりました。

アプリケーションが同じように機能することを確認したい場合は、次のコマンドを実行してください。それ以外の場合は次のモジュールに進むことができます。

```bash timeout=240
$ curl --head -X GET --retry 30 --retry-all-errors --retry-delay 15 --connect-timeout 30 --max-time 60 \
  -k $(kubectl get service -n ui ui-nlb -o jsonpath="{.status.loadBalancer.ingress[*].hostname}")
```
