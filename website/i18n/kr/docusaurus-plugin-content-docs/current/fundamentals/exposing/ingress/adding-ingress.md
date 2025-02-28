---
title: "Ingress 생성"
sidebar_position: 20
---
다음 구성으로 Ingress 리소스를 생성해보겠습니다:

::yaml{file="manifests/modules/exposing/ingress/creating-ingress/ingress.yaml" paths="kind,metadata.annotations,spec.rules.0"}

* `Ingress` 종류 사용
* 어노테이션을 사용하여 대상 pod에 대한 상태 확인과 같은 ALB의 다양한 동작을 구성할 수 있습니다
* rules 섹션은 ALB가 트래픽을 어떻게 라우팅해야 하는지 표현하는 데 사용됩니다.
  이 예제에서는 경로가 `/`로 시작하는 모든 HTTP 요청을 포트 80의 `ui`라는 Kubernetes 서비스로 라우팅합니다

이 구성을 적용합니다:

```bash
$ kubectl apply -k ~/environment/eks-workshop/modules/exposing/ingress/creating-ingress
```

생성된 Ingress 객체를 검사해보겠습니다:

```bash
$ kubectl get ingress ui -n ui
NAME   CLASS   HOSTS   ADDRESS                                            PORTS   AGE
ui     alb     *       k8s-ui-ui-1268651632.us-west-2.elb.amazonaws.com   80      15s
```

ALB가 프로비저닝되고 대상을 등록하는 데 몇 분이 걸리므로, 이 Ingress에 대해 프로비저닝된 ALB가 어떻게 구성되었는지 자세히 살펴보겠습니다:

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

이것이 우리에게 알려주는 것은 무엇일까요?

* ALB는 공용 인터넷을 통해 접근 가능합니다
* VPC의 공용 서브넷을 사용합니다

컨트롤러가 생성한 대상 그룹의 대상을 검사합니다:

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

Ingress 객체에서 IP 모드 사용을 지정했기 때문에, 대상은 `ui` pod의 IP 주소와 트래픽을 처리하는 포트를 사용하여 등록됩니다.

이 링크를 클릭하여 콘솔에서 ALB와 해당 대상 그룹을 검사할 수도 있습니다:

<ConsoleButton url="https://console.aws.amazon.com/ec2/home#LoadBalancers:tag:ingress.k8s.aws/stack=ui/ui;sort=loadBalancerName" service="ec2" label="Open EC2 console"/>

Ingress 리소스에서 URL을 가져옵니다:

```bash
$ kubectl get ingress -n ui ui -o jsonpath="{.status.loadBalancer.ingress[*].hostname}{'\n'}"
k8s-ui-uinlb-a9797f0f61.elb.us-west-2.amazonaws.com
```

로드 밸런서의 프로비저닝이 완료될 때까지 기다리려면 다음 명령을 실행할 수 있습니다:

```bash
$ wait-for-lb $(kubectl get ingress -n ui ui -o jsonpath="{.status.loadBalancer.ingress[*].hostname}{'\n'}")
```

웹 브라우저에서 접근하면 웹 스토어의 UI가 표시되고 사용자로서 사이트를 둘러볼 수 있습니다.

<Browser url="http://k8s-ui-ui-a9797f0f61.elb.us-west-2.amazonaws.com">
<img src={require('@site/static/img/sample-app-screens/home.webp').default}/>
</Browser>
