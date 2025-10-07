---
title: "Ingressの作成"
sidebar_position: 20
kiteTranslationSourceHash: 55ba2d304b8961fd6c8455b49eb75f66
---

以下の構成で Ingress リソースを作成しましょう：

::yaml{file="manifests/modules/exposing/ingress/creating-ingress/ingress.yaml" paths="kind,metadata.annotations,spec.rules.0"}

1. `Ingress` の種類を使用
2. アノテーションを使用して、作成される ALB の様々な動作（ターゲットポッドに対して実行するヘルスチェックなど）を設定できます
3. rules セクションは、ALB がトラフィックをどのようにルーティングすべきかを表現するために使用されます。この例では、パスが `/` から始まる全ての HTTP リクエストを、ポート 80 で `ui` という名前の Kubernetes サービスにルーティングしています

この設定を適用しましょう：

```bash timeout=180 hook=add-ingress hookTimeout=430
$ kubectl apply -k ~/environment/eks-workshop/modules/exposing/ingress/creating-ingress
```

作成された Ingress オブジェクトを確認しましょう：

```bash
$ kubectl get ingress ui -n ui
NAME   CLASS   HOSTS   ADDRESS                                            PORTS   AGE
ui     alb     *       k8s-ui-ui-1268651632.us-west-2.elb.amazonaws.com   80      15s
```

ALB はターゲットをプロビジョニングして登録するのに数分かかりますので、この Ingress 用にプロビジョニングされた ALB をより詳しく見てみましょう：

```bash
$ aws elbv2 describe-load-balancers --query 'LoadBalancers[?contains(LoadBalancerName, `k8s-ui-ui`) == `true`]'
[
    {
        "LoadBalancerArn": "arn:aws:elasticloadbalancing:us-west-2:1234567890:loadbalancer/app/k8s-ui-ui-cb8129ddff/f62a7bc03db28e7c",
        "DNSName": "k8s-ui-ui-cb8129ddff-1888909706.us-west-2.elb.amazonaws.com",
        "CanonicalHostedZoneId": "Z1H1FL5HABSF5",
        "CreatedTime": "2022-09-30T03:40:00.950000+00:00",
        "LoadBalancerName": "k8s-ui-ui-cb8129ddff",
        "Scheme": "internet-facing",
        "VpcId": "vpc-0851f873025a2ece5",
        "State": {
            "Code": "active"
        },
        "Type": "application",
        "AvailabilityZones": [
            {
                "ZoneName": "us-west-2b",
                "SubnetId": "subnet-00415f527bbbd999b",
                "LoadBalancerAddresses": []
            },
            {
                "ZoneName": "us-west-2a",
                "SubnetId": "subnet-0264d4b9985bd8691",
                "LoadBalancerAddresses": []
            },
            {
                "ZoneName": "us-west-2c",
                "SubnetId": "subnet-05cda6deed7f3da65",
                "LoadBalancerAddresses": []
            }
        ],
        "SecurityGroups": [
            "sg-0f8e704ee37512eb2",
            "sg-02af06ec605ef8777"
        ],
        "IpAddressType": "ipv4"
    }
]
```

これは何を教えてくれるでしょうか？

- ALB はインターネット経由でアクセス可能です
- VPC のパブリックサブネットを使用しています

コントローラーによって作成されたターゲットグループのターゲットを確認しましょう：

```bash
$ ALB_ARN=$(aws elbv2 describe-load-balancers --query 'LoadBalancers[?contains(LoadBalancerName, `k8s-ui-ui`) == `true`].LoadBalancerArn' | jq -r '.[0]')
$ TARGET_GROUP_ARN=$(aws elbv2 describe-target-groups --load-balancer-arn $ALB_ARN | jq -r '.TargetGroups[0].TargetGroupArn')
$ aws elbv2 describe-target-health --target-group-arn $TARGET_GROUP_ARN
{
    "TargetHealthDescriptions": [
        {
            "Target": {
                "Id": "10.42.180.183",
                "Port": 8080,
                "AvailabilityZone": "us-west-2c"
            },
            "HealthCheckPort": "8080",
            "TargetHealth": {
                "State": "healthy"
            }
        }
    ]
}
```

Ingress オブジェクトで IP モードを指定したので、ターゲットは `ui` ポッドの IP アドレスとトラフィックを提供するポートを使用して登録されます。

次のリンクをクリックすると、コンソールで ALB とそのターゲットグループを確認することもできます：

<ConsoleButton url="https://console.aws.amazon.com/ec2/home#LoadBalancers:tag:ingress.k8s.aws/stack=ui/ui;sort=loadBalancerName" service="ec2" label="EC2コンソールを開く"/>

Ingress リソースから URL を取得しましょう：

```bash
$ ADDRESS=$(kubectl get ingress -n ui ui -o jsonpath="{.status.loadBalancer.ingress[*].hostname}")
$ echo "http://${ADDRESS}"
http://k8s-ui-ui-a9797f0f61.elb.us-west-2.amazonaws.com
```

ロードバランサーのプロビジョニングが完了するまで待つには、次のコマンドを実行できます：

```bash
$ curl --head -X GET --retry 30 --retry-all-errors --retry-delay 15 --connect-timeout 30 --max-time 60 \
  -k $(kubectl get ingress -n ui ui -o jsonpath="{.status.loadBalancer.ingress[*].hostname}")
```

そして Web ブラウザでアクセスしてみましょう。Web ストアの UI が表示され、ユーザーとしてサイト内を移動することができます。

<Browser url="http://k8s-ui-ui-a9797f0f61.elb.us-west-2.amazonaws.com">
<img src={require('@site/static/img/sample-app-screens/home.webp').default}/>
</Browser>
