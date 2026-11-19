---
title: "複数のIngressパターン"
sidebar_position: 30
tmdTranslationSourceHash: '692d689ce678f8898dea14b6e79d6577'
---

同じEKSクラスター内で複数のIngressオブジェクトを活用することは一般的です。例えば、複数の異なるワークロードを公開するためなどです。デフォルトでは、各IngressはそれぞれALBの作成につながりますが、IngressGroup機能を活用することで複数のIngressリソースをグループ化できます。コントローラーはIngressGroup内のすべてのIngressのルールを自動的に統合し、1つのALBでそれらをサポートします。さらに、Ingressで定義されたほとんどのアノテーションは、そのIngressによって定義されたパスにのみ適用されます。

この例では、`ui`コンポーネントと同じALBを通して`catalog` APIを公開し、パスベースのルーティングを活用して適切なKubernetesサービスにリクエストをディスパッチします。

まず、`ui`コンポーネントの新しいIngressを作成します：

::yaml{file="manifests/modules/exposing/ingress/multiple-ingress/ingress-ui.yaml" paths="metadata.annotations,spec.rules.0"}

1. アノテーション`alb.ingress.kubernetes.io/group.name`を追加してIngressGroupを`retail-app-group`に設定します
2. rulesセクションは、ALBがトラフィックをどのようにルーティングすべきかを表現するために使用されます。`ui`コンポーネントでは、パス`/`で始まるすべてのHTTPリクエストをポート80のKubernetesサービス`ui`にルーティングします

次に、`catalog`コンポーネント用に別のIngressを作成します：

::yaml{file="manifests/modules/exposing/ingress/multiple-ingress/ingress-catalog.yaml" paths="metadata.annotations,spec.rules.0"}

1. `ui`コンポーネントと同じIngressGroupを指定するには、アノテーションセクションで`alb.ingress.kubernetes.io/group.name`を`retail-app-group`に設定します
2. rulesセクションは、ALBがトラフィックをどのようにルーティングすべきかを表現するために使用されます。`catalog`コンポーネントでは、パス`/catalog`で始まるすべてのHTTPリクエストをポート80のKubernetesサービス`catalog`にルーティングします

これらのマニフェストをクラスターに適用します：

```bash wait=60
$ kubectl kustomize ~/environment/eks-workshop/modules/exposing/ingress/multiple-ingress | envsubst | kubectl apply -f -
ingress.networking.k8s.io/catalog-multi created
ingress.networking.k8s.io/ui-multi created
```

これで、`-multi`で終わる2つの追加のIngressオブジェクトがクラスターに作成されます：

```bash
$ kubectl get ingress -l app.kubernetes.io/created-by=eks-workshop -A
NAMESPACE   NAME            CLASS   HOSTS   ADDRESS                                                                PORTS   AGE
catalog     catalog-multi   alb     *       k8s-retailappgroup-085b071a94-1735886616.us-west-2.elb.amazonaws.com   80      4m6s
ui          ui-multi        alb     *       k8s-retailappgroup-085b071a94-1735886616.us-west-2.elb.amazonaws.com   80      4m6s
```

両方の`ADDRESS`が同じURLであることに注目してください。これは、これら2つのIngressオブジェクトが同じALBの背後にグループ化されているためです。

ALBリスナーを見て、これがどのように機能するか確認しましょう：

```bash
$ ALB_ARN=$(aws elbv2 describe-load-balancers --query 'LoadBalancers[?contains(LoadBalancerName, `k8s-retailappgroup`) == `true`].LoadBalancerArn' | jq -r '.[0]')
$ LISTENER_ARN=$(aws elbv2 describe-listeners --load-balancer-arn $ALB_ARN | jq -r '.Listeners[0].ListenerArn')
$ aws elbv2 describe-rules --listener-arn $LISTENER_ARN
{
    "Rules": [
        {
            [...]
            "Priority": "1",
            "Conditions": [
                {
                    "Field": "path-pattern",
                    "Values": [
                        "/catalog",
                        "/catalog/*"
                    ],
                    [...]
                }
            ],
            "Actions": [
                {
                    "Type": "forward",
                    "TargetGroupArn": "arn:aws:elasticloadbalancing:us-west-2:1234567890:targetgroup/k8s-catalog-catalog-dd063e5d63/0ca7a01dcfe0e890",
                    [...]
                }
            ],
            "IsDefault": false,
            [...]
        },
        {
            [...]
            "Priority": "2",
            "Conditions": [
                {
                    "Field": "path-pattern",
                    "Values": [
                        "/*"
                    ],
                    [...]
                }
            ],
            "Actions": [
                {
                    "Type": "forward",
                    "TargetGroupArn": "arn:aws:elasticloadbalancing:us-west-2:1234567890:targetgroup/k8s-ui-ui-a01d749064/e15407cbc96752aa",
                    [...]
                }
            ],
            "IsDefault": false,
            [...]
        },
        {
            [...]
            "Priority": "default",
            "Conditions": [],
            "Actions": [
                {
                    "Type": "fixed-response",
                    "Order": 1,
                    "FixedResponseConfig": {
                        "StatusCode": "404",
                        "ContentType": "text/plain"
                    }
                }
            ],
            "IsDefault": true,
            [...]
        }
    ]
}
```

このコマンドの出力は次のことを示します：

- パスプレフィックス`/catalog`を持つリクエストはcatalogサービスのターゲットグループに送信されます
- それ以外はuiサービスのターゲットグループに送信されます
- デフォルトのバックアップとして、漏れたリクエストのために404があります

AWSコンソールで新しいALB設定も確認できます：

<ConsoleButton url="https://console.aws.amazon.com/ec2/home#LoadBalancers:tag:ingress.k8s.aws/stack=retail-app-group;sort=loadBalancerName" service="ec2" label="EC2コンソールを開く"/>

ロードバランサーのプロビジョニングが完了するまで待つには、次のコマンドを実行できます：

```bash timeout=180
$ curl --head -X GET --retry 30 --retry-all-errors --retry-delay 15 --connect-timeout 30 --max-time 60 \
  -k $(kubectl get ingress -n catalog catalog-multi -o jsonpath="{.status.loadBalancer.ingress[*].hostname}")
curl: (6) Could not resolve host: k8s-retailappgroup-085b071a94-1735886616.us-west-2.elb.amazonaws.com
Warning: Problem : timeout. Retrying in 15 seconds. 30 retries left.
[...]
HTTP/1.1 200 OK
Date: Sat, 31 Oct 2026 14:06:39 GMT
Content-Type: text/html
Content-Length: 19973
Connection: keep-alive
Content-Language: en-US
set-cookie: SESSIONID=5a80431f-672b-4b2e-9afc-b305b332e067
```

以前と同様にブラウザで新しいIngress URLにアクセスして、Webユーザーインターフェイスがまだ機能していることを確認してください：

```bash
$ ADDRESS=$(kubectl get ingress -n catalog catalog-multi -o jsonpath="{.status.loadBalancer.ingress[*].hostname}")
$ echo "http://${ADDRESS}"
http://k8s-retailappgroup-085b071a94-1735886616.us-west-2.elb.amazonaws.com
```

次に、catalogサービスに向けたパスにアクセスしてみましょう：

```bash
$ ADDRESS=$(kubectl get ingress -n catalog catalog-multi -o jsonpath="{.status.loadBalancer.ingress[*].hostname}")
$ curl $ADDRESS/catalog/products | jq .
[
  {
    "id": "a1258cd2-176c-4507-ade6-746dab5ad625",
    "name": "Aqua Ace GT",
    "description": "Transform your luxury sports car into a high-speed submarine with the push of a button. Features hydro-jet propulsion, underwater navigation, and oxygen recycling system for up to 8 hours. Includes coral-proof paint coating.",
    "price": 10000,
    "tags": [
      {
        "name": "vehicles",
        "displayName": "Vehicles"
      }
    ]
  },
  {
    "id": "d4edfedb-dbe9-4dd9-aae8-009489394955",
    "name": "Audio-Illusion Spinner",
    "description": "Professional-grade sonic illusion generator disguised as a simple yo-yo. Creates realistic sound effects from footsteps to full orchestras. Includes comprehensive training manual and anti-tangle technology.",
    "price": 190,
    "tags": [
      {
        "name": "accessories",
        "displayName": "Accessories"
      }
    ]
  },
  [...]
]
```

catalogサービスからJSONペイロードが返されます。これは、同じALBを通じて複数のKubernetesサービスを公開できたことを示しています。

