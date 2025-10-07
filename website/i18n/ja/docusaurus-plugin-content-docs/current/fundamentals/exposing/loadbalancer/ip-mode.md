---
title: "IPモード"
sidebar_position: 40
kiteTranslationSourceHash: 0678635ca0b190ccd6ebe40b82cd6c99
---

前述のように、作成したNLBは「インスタンスモード」で動作しています。インスタンスターゲットモードはAWS EC2インスタンス上で実行されているポッドをサポートしています。このモードでは、AWS NLBはインスタンスにトラフィックを送信し、個々のワーカーノード上の`kube-proxy`がKubernetesクラスター内の1つ以上のワーカーノードを介してポッドにトラフィックを転送します。

AWS Load Balancer Controllerは、「IPモード」で動作するNLBの作成もサポートしています。このモードでは、AWS NLBはKubernetesクラスター内のワーカーノードを経由する余分なネットワークホップを排除して、サービスの背後にあるKubernetesポッドに直接トラフィックを送信します。IPターゲットモードは、AWS EC2インスタンスとAWS Fargateの両方で実行されているポッドをサポートしています。

![IPモード](./assets/ip-mode.webp)

前の図は、ターゲットグループモードがインスタンスとIPの場合で、アプリケーショントラフィックの流れがどのように異なるかを説明しています。

ターゲットグループモードがインスタンスの場合、トラフィックは各ノードに作成されたサービスのノードポート経由で流れます。このモードでは、`kube-proxy`がこのサービスを実行しているポッドにトラフィックをルーティングします。サービスポッドは、ロードバランサーからトラフィックを受信したノードとは異なるノードで実行されている可能性があります。ServiceA（緑）とServiceB（ピンク）は「インスタンスモード」で動作するように設定されています。

一方、ターゲットグループモードがIPの場合、トラフィックはロードバランサーからサービスポッドに直接流れます。このモードでは、`kube-proxy`のネットワークホップをバイパスします。ServiceC（青）は「IPモード」で動作するように設定されています。

前の図の数字は以下を表しています。

1. サービスがデプロイされているEKSクラスター
2. サービスを公開するELBインスタンス
3. インスタンスまたはIPのいずれかに設定できるターゲットグループモードの設定
4. サービスが公開されているロードバランサーに設定されたリスナープロトコル
5. サービスの宛先を決定するために使用されるターゲットグループルール設定

NLBをIPターゲットモードで構成したい理由はいくつかあります：

1. 受信接続のためのより効率的なネットワークパスを作成し、EC2ワーカーノード上の`kube-proxy`をバイパスします
2. `externalTrafficPolicy`や様々な構成オプションのトレードオフなどの側面を考慮する必要がなくなります
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
$ kubectl apply -k ~/environment/eks-workshop/modules/exposing/load-balancer/ip-mode
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
$ ALB_ARN=$(aws elbv2 describe-load-balancers --query 'LoadBalancers[?contains(LoadBalancerName, `k8s-ui-uinlb`) == `true`].LoadBalancerArn' | jq -r '.[0]')
$ TARGET_GROUP_ARN=$(aws elbv2 describe-target-groups --load-balancer-arn $ALB_ARN | jq -r '.TargetGroups[0].TargetGroupArn')
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

前のセクションで観察した3つのターゲットから、たった1つのターゲットに変わっていることに注目してください。なぜでしょうか？EKSクラスター内のEC2インスタンスを登録する代わりに、ロードバランサーコントローラーは現在個々のポッドを登録し、トラフィックを直接送信しています。これはAWS VPC CNIとポッドそれぞれがファーストクラスのVPC IPアドレスを持つという事実を活用しています。

uiコンポーネントを3つのレプリカにスケールアップして、何が起こるか見てみましょう：

```bash
$ kubectl scale -n ui deployment/ui --replicas=3
$ kubectl wait --for=condition=Ready pod -n ui -l app.kubernetes.io/name=ui --timeout=60s
```

ロードバランサーのターゲットを再度確認します：

```bash
$ ALB_ARN=$(aws elbv2 describe-load-balancers --query 'LoadBalancers[?contains(LoadBalancerName, `k8s-ui-uinlb`) == `true`].LoadBalancerArn' | jq -r '.[0]')
$ TARGET_GROUP_ARN=$(aws elbv2 describe-target-groups --load-balancer-arn $ALB_ARN | jq -r '.TargetGroups[0].TargetGroupArn')
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

予想通り、uiデプロイメントのレプリカ数に一致する3つのターゲットが表示されるようになりました。

アプリケーションが同じように機能することを確認したい場合は、次のコマンドを実行してください。それ以外の場合は次のモジュールに進むことができます。

```bash timeout=240
$ curl --head -X GET --retry 30 --retry-all-errors --retry-delay 15 --connect-timeout 30 --max-time 60 \
  -k $(kubectl get service -n ui ui-nlb -o jsonpath="{.status.loadBalancer.ingress[*].hostname}")
```
