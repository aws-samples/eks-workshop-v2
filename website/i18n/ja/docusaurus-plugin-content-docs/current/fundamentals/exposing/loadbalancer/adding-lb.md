---
title: "ロードバランサーの作成"
sidebar_position: 20
tmdTranslationSourceHash: 10d2bea65be51068244e993bee3c0d60
---

以下の設定でロードバランサーをプロビジョニングする追加のServiceを作成しましょう：

::yaml{file="manifests/modules/exposing/load-balancer/nlb/nlb.yaml" paths="spec.type,spec.ports,spec.selector"}

1. この`Service`はネットワークロードバランサーを作成します
2. NLBはポート80でリッスンし、`ui` Podsのポート8080に接続を転送します
3. ここでは、ポッド上のラベルを使用して、このサービスのターゲットに追加するポッドを指定します

この設定を適用します：

```bash timeout=180 hook=add-lb hookTimeout=430
$ kubectl apply -k ~/environment/eks-workshop/modules/exposing/load-balancer/nlb
```

`ui`アプリケーションのService リソースを再度確認してみましょう：

```bash
$ kubectl get service -n ui
NAME     TYPE           CLUSTER-IP      EXTERNAL-IP                                                            PORT(S)        AGE
ui       ClusterIP      172.16.69.215   <none>                                                                 80/TCP         7m38s
ui-nlb   LoadBalancer   172.16.77.201   k8s-ui-uinlb-e1c1ebaeb4-28a0d1a388d43825.elb.us-west-2.amazonaws.com   80:30549/TCP   105s
```

`ui-nlb`という新しいエントリーが`LoadBalancer`タイプであることがわかります。最も重要なのは「external IP」の値で、これはKubernetesクラスター外からアプリケーションにアクセスするために使用できるDNSエントリーです。

NLBのプロビジョニングとターゲットの登録には数分かかりますので、コントローラーが作成したロードバランサーリソースを確認する時間を取りましょう。

まず、ロードバランサー自体を見てみましょう：

```bash
$ aws elbv2 describe-load-balancers --query 'LoadBalancers[?contains(LoadBalancerName, `k8s-ui-uinlb`) == `true`]'
[
    {
        "LoadBalancerArn": "arn:aws:elasticloadbalancing:us-west-2:1234567890:loadbalancer/net/k8s-ui-uinlb-e1c1ebaeb4/28a0d1a388d43825",
        "DNSName": "k8s-ui-uinlb-e1c1ebaeb4-28a0d1a388d43825.elb.us-west-2.amazonaws.com",
        "CanonicalHostedZoneId": "Z18D5FSROUN65G",
        "CreatedTime": "2022-11-17T04:47:30.516000+00:00",
        "LoadBalancerName": "k8s-ui-uinlb-e1c1ebaeb4",
        "Scheme": "internet-facing",
        "VpcId": "vpc-00be6fc048a845469",
        "State": {
            "Code": "active"
        },
        "Type": "network",
        "AvailabilityZones": [
            {
                "ZoneName": "us-west-2c",
                "SubnetId": "subnet-0a2de0809b8ee4e39",
                "LoadBalancerAddresses": []
            },
            {
                "ZoneName": "us-west-2a",
                "SubnetId": "subnet-0ff71604f5b58b2ba",
                "LoadBalancerAddresses": []
            },
            {
                "ZoneName": "us-west-2b",
                "SubnetId": "subnet-0c584c4c6a831e273",
                "LoadBalancerAddresses": []
            }
        ],
        "SecurityGroups": [
            "sg-03688f7b9bef3fc57",
            "sg-09743892e52e82896"
        ],
        "IpAddressType": "ipv4",
        "EnablePrefixForIpv6SourceNat": "off"
    }
]
```

これは何を意味しますか？

- NLBはパブリックインターネット経由でアクセス可能です
- VPC内のパブリックサブネットを使用しています

コントローラーによって作成されたターゲットグループ内のターゲットも確認できます：

```bash
$ ALB_ARN=$(aws elbv2 describe-load-balancers --query 'LoadBalancers[?contains(LoadBalancerName, `k8s-ui-uinlb`) == `true`].LoadBalancerArn' | jq -r '.[0]')
$ TARGET_GROUP_ARN=$(aws elbv2 describe-target-groups --load-balancer-arn $ALB_ARN | jq -r '.TargetGroups[0].TargetGroupArn')
$ aws elbv2 describe-target-health --target-group-arn $TARGET_GROUP_ARN
{
    "TargetHealthDescriptions": [
        {
            "Target": {
                "Id": "i-03d705cd2404b089d",
                "Port": 30549
            },
            "HealthCheckPort": "30549",
            "TargetHealth": {
                "State": "healthy"
            },
            "AdministrativeOverride": {
                "State": "no_override",
                "Reason": "AdministrativeOverride.NoOverride",
                "Description": "No override is currently active on target"
            }
        },
        {
            "Target": {
                "Id": "i-0d33c31067a053ece",
                "Port": 30549
            },
            "HealthCheckPort": "30549",
            "TargetHealth": {
                "State": "healthy"
            },
            "AdministrativeOverride": {
                "State": "no_override",
                "Reason": "AdministrativeOverride.NoOverride",
                "Description": "No override is currently active on target"
            }
        },
        {
            "Target": {
                "Id": "i-0c221e809e435b965",
                "Port": 30549
            },
            "HealthCheckPort": "30549",
            "TargetHealth": {
                "State": "healthy"
            },
            "AdministrativeOverride": {
                "State": "no_override",
                "Reason": "AdministrativeOverride.NoOverride",
                "Description": "No override is currently active on target"
            }
        }
    ]
}
```

上記の出力から、同じポート上でEC2インスタンスID（`i-`）を使用して3つのターゲットがロードバランサーに登録されていることがわかります。これは、デフォルトでAWS Load Balancer Controllerが「インスタンスモード」で動作しており、EKSクラスター内のワーカーノードにトラフィックを転送し、`kube-proxy`が個々のPodにトラフィックを転送できるようにしているためです。

このリンクをクリックしてコンソールでNLBを確認することもできます：

<ConsoleButton url="https://console.aws.amazon.com/ec2/home#LoadBalancers:tag:service.k8s.aws/stack=ui/ui-nlb;sort=loadBalancerName" service="ec2" label="Open EC2 console"/>

ServiceリソースからURLを取得します：

```bash
$ ADDRESS=$(kubectl get service -n ui ui-nlb -o jsonpath="{.status.loadBalancer.ingress[*].hostname}")
$ echo "http://${ADDRESS}"
http://k8s-ui-uinlb-e1c1ebaeb4-28a0d1a388d43825.elb.us-west-2.amazonaws.com
```

ロードバランサーのプロビジョニングが完了するまで待つには、次のコマンドを実行できます：

```bash
$ curl --head -X GET --retry 30 --retry-all-errors --retry-delay 15 --connect-timeout 30 --max-time 60 \
  -k $(kubectl get service -n ui ui-nlb -o jsonpath="{.status.loadBalancer.ingress[*].hostname}")
```

これでアプリケーションが外部に公開されたので、ウェブブラウザにそのURLを貼り付けてアクセスしてみましょう。ウェブストアのUIが表示され、ユーザーとしてサイト内を移動することができるようになります。

<Browser url="http://k8s-ui-uinlb-e1c1ebaeb4-28a0d1a388d43825.elb.us-west-2.amazonaws.com">
<img src={require('@site/static/img/sample-app-screens/home.webp').default}/>
</Browser>
