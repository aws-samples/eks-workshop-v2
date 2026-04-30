---
title: "Ingress の作成"
sidebar_position: 20
tmdTranslationSourceHash: '7853bafb8c4cf75d9cae7be70165679f'
---

:::info AWS Load Balancer Controller
AWS Load Balancer Controller は Amazon EKS Auto Mode に含まれており、コントロールプレーンで実行されます。Ingress リソースを作成すると、自動的に AWS ロードバランサーがプロビジョニングされます。
:::

現在、クラスターには Ingress リソースが存在しません。これは次のコマンドで確認できます:

```bash expectError=true
$ kubectl get ingress -n ui
No resources found in ui namespace.
```

まず、IngressClass と IngressClassParams を設定する必要があります:

::yaml{file="manifests/modules/fastpaths/developers/ingress/adding-ingress/ingressclass.yaml" paths="0.spec.controller,0.spec.parameters,1.spec"}

1. `controller` フィールドは、Auto Mode ALB 機能をターゲットにするために `eks.amazonaws.com/alb` に設定する必要があります
2. `parameters` セクションは、`apiGroup: eks.amazonaws.com` を持つ IngressClassParams リソースを参照します
3. IngressClassParams は、ロードバランサーのスキームやターゲットタイプなど、AWS 固有の設定を定義します

この IngressClass を使用して、Ingress を設定します:

::yaml{file="manifests/modules/fastpaths/developers/ingress/adding-ingress/ingress.yaml" paths="kind,spec.ingressClassName,spec.rules"}

1. `Ingress` kind を使用します
2. `ingressClassName` は Auto Mode IngressClass を参照します
3. rules セクションは、パスが `/` で始まるすべての HTTP リクエストを、ポート 80 の `ui` という Kubernetes Service にルーティングします

:::info
EKS Auto Mode では、アノテーションによる ALB 設定はサポートされていません。設定は IngressClassParams で行う必要があります。
:::

それでは、これらの設定を適用しましょう:

```bash timeout=180 hook=add-ingress hookTimeout=660
$ kubectl kustomize ~/environment/eks-workshop/modules/fastpaths/developers/ingress/adding-ingress | envsubst | kubectl apply -f -
```

作成された Ingress オブジェクトを確認しましょう:

```bash
$ kubectl get ingress ui-auto -n ui
NAME   CLASS          HOSTS   ADDRESS                                                     PORTS   AGE
ui-auto     eks-auto-alb   *       k8s-ui-uiauto-6cd0ef095e-78768930.us-west-2.elb.amazonaws.com   80      5s
```

ALB のプロビジョニングとターゲットの登録には数分かかるため、この Ingress 用にプロビジョニングされた ALB がどのように設定されているかを詳しく見てみましょう:

```bash
$ aws elbv2 describe-load-balancers --query 'LoadBalancers[?contains(LoadBalancerName, `k8s-ui-uiauto`) == `true`]'
[
    {
        "LoadBalancerArn": "arn:aws:elasticloadbalancing:us-west-2:1234567890:loadbalancer/app/k8s-ui-uiauto-cb8129ddff/f62a7bc03db28e7c",
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

これから何がわかるでしょうか？

- ALB はパブリックインターネット経由でアクセス可能です
- VPC 内のパブリックサブネットを使用しています

コントローラーによって作成されたターゲットグループ内のターゲットを確認します:

```bash
$ ALB_ARN=$(aws elbv2 describe-load-balancers --query 'LoadBalancers[?contains(LoadBalancerName, `k8s-ui-uiauto`) == `true`].LoadBalancerArn' | jq -r '.[0]')
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

Ingress オブジェクトで IP モードの使用を指定したため、ターゲットは `ui` Pod の IP アドレスとトラフィックを提供するポートを使用して登録されます。

このリンクをクリックして、コンソールで ALB とそのターゲットグループを確認することもできます:

<ConsoleButton url="https://console.aws.amazon.com/ec2/home#LoadBalancers:tag:ingress.eks.amazonaws.com/stack=ui/ui-auto;sort=loadBalancerName" service="ec2" label="EC2 コンソールを開く"/>

:::caution
このボタンを使用してコンソールを開く際に問題が発生した場合は、AWS コンソールのアクティブなセッションがない可能性があります。この問題を解決するには、ワークショップのホームページに移動し、左側のナビゲーションメニューの `AWS account access` セクションにある `Open AWS console` というリンクをクリックしてください。
:::

Ingress リソースから URL を取得します:

```bash
$ ADDRESS=$(kubectl get ingress -n ui ui-auto -o jsonpath="{.status.loadBalancer.ingress[*].hostname}")
$ echo "http://${ADDRESS}"
http://k8s-ui-uiauto-cb8129ddff-1888909706.us-west-2.elb.amazonaws.com
```

ロードバランサーのプロビジョニングが完了するまで待つには、次のコマンドを実行します:

```bash timeout=600
$ curl --head -X GET --retry 30 --retry-all-errors --retry-delay 15 --connect-timeout 30 --max-time 60 \
  -k $(kubectl get ingress -n ui ui-auto -o jsonpath="{.status.loadBalancer.ingress[*].hostname}")
```

そして、Web ブラウザでアクセスしてください。Web ストアの UI が表示され、ユーザーとしてサイト内を移動できるようになります。

<Browser url="http://k8s-ui-uiauto-cb8129ddff-1888909706.us-west-2.elb.amazonaws.com">
<img src={require('@site/static/img/sample-app-screens/home.webp').default}/>
</Browser>

