---
title: "ALB が作成されない問題"
sidebar_position: 30
tmdTranslationSourceHash: aecb17a85e17e982a630345ead4ab416
---

このトラブルシューティングシナリオでは、AWS Load Balancer Controller が Ingress リソース用に Application Load Balancer（ALB）を作成しない理由を調査します。この演習の最後には、以下の画像のように ALB Ingress を通じて UI アプリケーションにアクセスできるようになります。

![ingress](/docs/troubleshooting/alb/ingress.webp)

## トラブルシューティングを始めましょう

### ステップ 1：アプリケーションのステータスを確認する

まず、UI アプリケーションのステータスを確認しましょう：

```bash
$ kubectl get pod -n ui
NAME                  READY   STATUS    RESTARTS   AGE
ui-68495c748c-jkh2z   1/1     Running   0          85s
```

### ステップ 2：Ingress ステータスを確認する

Ingress リソースを調べてみましょう。ADDRESS フィールドが空であることに注目してください - これは ALB が作成されていないことを示しています：

```bash
$ kubectl get ingress/ui -n ui
NAME   CLASS   HOSTS   ADDRESS   PORTS   AGE
ui     alb     *                 80      105s
```

正常にデプロイされた場合、ADDRESS フィールドには次のような ALB DNS 名が表示されます：

```text
NAME   CLASS   HOSTS   ADDRESS                                                    PORTS   AGE
ui     alb     *      k8s-ui-ingress-xxxxxxxxxx-yyyyyyyyyy.region.elb.amazonaws.com   80   2m32s
```

### ステップ 3：Ingress イベントを調査する

ALB 作成が失敗した理由を理解するために、Ingress に関連するイベントを見てみましょう：

```bash
$ kubectl describe ingress/ui -n ui
Name:             ui
Labels:           <none>
Namespace:        ui
Address:
Ingress Class:    alb
Default backend:  <default>
Rules:
  Host        Path  Backends
  ----        ----  --------
  *
              /   service-ui:80 (<error: endpoints "service-ui" not found>)
Annotations:  alb.ingress.kubernetes.io/healthcheck-path: /actuator/health/liveness
              alb.ingress.kubernetes.io/scheme: internet-facing
              alb.ingress.kubernetes.io/target-type: ip
Events:
  Type     Reason            Age                    From     Message
  ----     ------            ----                   ----     -------
  Warning  FailedBuildModel  2m23s (x16 over 5m9s)  ingress  Failed build model due to couldn't auto-discover subnets: unable to resolve at least one subnet (0 match VPC and tags: [kubernetes.io/role/elb])

```

このエラーは、AWS Load Balancer Controller がロードバランサーで使用するためにタグ付けされたサブネットを見つけることができないことを示しています。[ALB を EKS で正しく設定する](https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.4/deploy/subnet_discovery/)ためのドキュメントがあります。

### ステップ 4：サブネットタグを修正する

Load Balancer Controller は、パブリックサブネットに `kubernetes.io/role/elb=1` というタグが必要です。正しいサブネットを特定してタグ付けしましょう：

#### 4.1 クラスターのサブネットを見つける

```bash
$ aws ec2 describe-subnets --filters "Name=tag:alpha.eksctl.io/cluster-name,Values=${EKS_CLUSTER_NAME}" --query 'Subnets[].SubnetId[]'
[
      "subnet-xxxxxxxxxxxxxxxxx",
      "subnet-xxxxxxxxxxxxxxxxx",
      "subnet-xxxxxxxxxxxxxxxxx",
      "subnet-xxxxxxxxxxxxxxxxx",
      "subnet-xxxxxxxxxxxxxxxxx",
      "subnet-xxxxxxxxxxxxxxxxx"
]
```

#### 4.2. ルートテーブルを確認してどのサブネットがパブリックかを識別する

:::info
サブネット ID を CLI フィルターに一度に 1 つずつ追加することで、どのサブネットがパブリックかを識別できます：`--filters 'Name=association.subnet-id,Values=subnet-xxxxxxxxxxxxxxxxx'`

```text
aws ec2 describe-route-tables --filters 'Name=association.subnet-id,Values=<ここにサブネット ID を入力>' --query 'RouteTables[].Routes[].[DestinationCidrBlock,GatewayId]'

```

:::

```bash
$ for subnet_id in $(aws ec2 describe-subnets --filters "Name=tag:alpha.eksctl.io/cluster-name,Values=${EKS_CLUSTER_NAME}" --query 'Subnets[].SubnetId[]' --output text); do \
    echo "Subnet: ${subnet_id}"; \
    aws ec2 describe-route-tables --filters "Name=association.subnet-id,Values=${subnet_id}" \
      --query 'RouteTables[].Routes[].[DestinationCidrBlock,GatewayId]' --output text; \
done

Subnet: subnet-xxxxxxxxxxxxxxxxx
10.42.0.0/16    local
0.0.0.0/0       igw-xxxxxxxxxxxxxxxxx
Subnet: subnet-xxxxxxxxxxxxxxxxx
10.42.0.0/16    local
0.0.0.0/0       igw-xxxxxxxxxxxxxxxxx
...
```

パブリックサブネットは、Internet Gateway（igw-xxx）を指す `0.0.0.0/0` のルートを持っています。

#### 4.3. 現在の ELB タグのステータスを確認する

```bash
$ aws ec2 describe-subnets --filters 'Name=tag:kubernetes.io/role/elb,Values=1' --query 'Subnets[].SubnetId'
[]
```

#### 4.4. パブリックサブネットにタグ付けする（便宜上、環境変数に格納しています）

```bash
$ aws ec2 create-tags --resources $PUBLIC_SUBNET_1 $PUBLIC_SUBNET_2 $PUBLIC_SUBNET_3 \
      --tags 'Key="kubernetes.io/role/elb",Value=1'
```

#### 4.5. タグが適用されたことを確認する

```bash
$ aws ec2 describe-subnets --filters 'Name=tag:kubernetes.io/role/elb,Values=1' --query 'Subnets[].SubnetId'
```

#### 4.6. 新しいサブネット設定を取得するために Load Balancer Controller を再起動する

```bash
$ kubectl -n kube-system rollout restart deploy aws-load-balancer-controller
deployment.apps/aws-load-balancer-controller restarted
```

#### 4.7. Ingress ステータスを再確認する

```bash
$ kubectl describe ingress/ui -n ui
Warning  FailedDeployModel  50s  ingress  Failed deploy model due to AccessDenied: User: arn:aws:sts::021629549003:assumed-role/alb-controller-20250216203332410200000002/1739739040072980120 is not authorized to perform: elasticloadbalancing:CreateLoadBalancer on resource: arn:aws:elasticloadbalancing:us-west-2:021629549003:loadbalancer/app/k8s-ui-ui-5ddc3ba496/* because no identity-based policy allows the elasticloadbalancing:CreateLoadBalancer action
         status code: 403, request id: 33be0191-469b-4eff-840d-b5c9420f76c6
Warning  FailedDeployModel  9s (x5 over 49s)  ingress  (combined from similar events): Failed deploy model due to AccessDenied: User: arn:aws:sts::021629549003:assumed-role/alb-controller-20250216203332410200000002/1739739040072980120 is not authorized to perform: elasticloadbalancing:CreateLoadBalancer on resource: arn:aws:elasticloadbalancing:us-west-2:021629549003:loadbalancer/app/k8s-ui-ui-5ddc3ba496/* because no identity-based policy allows the elasticloadbalancing:CreateLoadBalancer action
         status code: 403, request id: a8d8f2c9-4911-4f3d-b4f3-81e2b0644e04
```

エラーが変わりました - 今度は IAM 権限の問題が見られ、これに対処する必要があります：

```text
Warning  FailedDeployModel  68s  ingress  Failed deploy model due to AccessDenied: User: arn:aws:sts::xxxxxxxxxxxx:assumed-role/alb-controller-20240611131524228000000002/1718115201989397805 is not authorized to perform: elasticloadbalancing:CreateLoadBalancer
```

これは、Load Balancer Controller の IAM 権限を修正する必要があることを示しており、次のセクションで対処します。

:::tip
CloudTrail で最近 1 時間以内の CreateLoadBalancer API 呼び出しを確認することで、ALB 作成の試みを検証できます。
:::
