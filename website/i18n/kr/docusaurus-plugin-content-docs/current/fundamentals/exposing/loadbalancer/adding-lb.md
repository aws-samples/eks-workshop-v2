---
title: "로드 밸런서 생성"
sidebar_position: 20
---

다음 구성으로 로드 밸런서를 프로비저닝하는 추가 Service를 생성해보겠습니다:

::yaml{file="manifests/modules/exposing/load-balancer/nlb/nlb.yaml" paths="spec.type,spec.ports,spec.selector"}

1. Network Load Balancer(NLB)로 생성합니다
2. NLB는 80번 포트에서 수신하고 8080 포트의 `ui` Pod로 연결을 전달합니다
3. 여기서는 pod의 레이블을 사용하여 이 서비스의 대상으로 추가될 Pod를 지정합니다

이 구성을 적용합니다:

```bash timeout=180 hook=add-lb hookTimeout=430
$ kubectl apply -k ~/environment/eks-workshop/modules/exposing/load-balancer/nlb
```

`ui` 애플리케이션의 Service 리소스를 다시 검사해보겠습니다:

```bash
$ kubectl get service -n ui
```

두 개의 별도 리소스가 보이며, 새로운 `ui-nlb` 항목이 LoadBalancer 타입입니다. 가장 중요한 점은 "external IP" 값이 있다는 것입니다. 이는 Kubernetes 클러스터 외부에서 우리 애플리케이션에 접근하는 데 사용할 수 있는 DNS 항목입니다.

NLB가 프로비저닝되고 대상을 등록하는 데 몇 분이 걸리므로, 컨트롤러가 생성한 로드 밸런서 리소스를 검사하는 데 시간이 필요합니다.

먼저 로드 밸런서 자체를 살펴보겠습니다:

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
        "IpAddressType": "ipv4"
    }
]
```

이것이 우리에게 알려주는 것은 무엇일까요?

- NLB는 공용 인터넷을 통해 접근 가능합니다
- VPC의 공용 서브넷을 사용합니다

또한 컨트롤러가 생성한 대상 그룹의 대상들을 검사할 수 있습니다:

```bash
$ ALB_ARN=$(aws elbv2 describe-load-balancers --query 'LoadBalancers[?contains(LoadBalancerName, `k8s-ui-uinlb`) == `true`].LoadBalancerArn' | jq -r '.[0]')
$ TARGET_GROUP_ARN=$(aws elbv2 describe-target-groups --load-balancer-arn $ALB_ARN | jq -r '.TargetGroups[0].TargetGroupArn')
$ aws elbv2 describe-target-health --target-group-arn $TARGET_GROUP_ARN
{
    "TargetHealthDescriptions": [
        {
            "Target": {
                "Id": "i-06a12e62c14e0c39a",
                "Port": 31338
            },
            "HealthCheckPort": "31338",
            "TargetHealth": {
                "State": "healthy"
            }
        },
        {
            "Target": {
                "Id": "i-088e21d0af0f2890c",
                "Port": 31338
            },
            "HealthCheckPort": "31338",
            "TargetHealth": {
                "State": "healthy"
            }
        },
        {
            "Target": {
                "Id": "i-0fe2202d18299816f",
                "Port": 31338
            },
            "HealthCheckPort": "31338",
            "TargetHealth": {
                "State": "healthy"
            }
        }
    ]
}
```

위의 출력은 동일한 포트의 EC2 인스턴스 ID(`i-`)를 사용하여 로드 밸런서에 등록된 3개의 대상이 있음을 보여줍니다. 이는 AWS Load Balancer 컨트롤러가 기본적으로 "instance mode"로 작동하기 때문입니다. 이 모드에서는 EKS 클러스터의 워커 노드를 대상으로 하고 `kube-proxy`가 개별 Pod로 트래픽을 전달할 수 있게 합니다.

이 링크를 클릭하여 콘솔에서 NLB를 검사할 수도 있습니다:

<ConsoleButton url="https://console.aws.amazon.com/ec2/home#LoadBalancers:tag:service.k8s.aws/stack=ui/ui-nlb;sort=loadBalancerName" service="ec2" label="Open EC2 console"/>

Service 리소스에서 URL을 가져옵니다:

```bash
$ kubectl get service -n ui ui-nlb -o jsonpath="{.status.loadBalancer.ingress[*].hostname}{'\n'}"
k8s-ui-uinlb-a9797f0f61.elb.us-west-2.amazonaws.com
```

로드 밸런서의 프로비저닝이 완료될 때까지 기다리려면 다음 명령을 실행할 수 있습니다:

```bash
$ wait-for-lb $(kubectl get service -n ui ui-nlb -o jsonpath="{.status.loadBalancer.ingress[*].hostname}{'\n'}")
```

이제 우리 애플리케이션이 외부 세계에 노출되었으니, 웹 브라우저에 해당 URL을 붙여넣어 접근해보겠습니다. 웹 스토어의 UI가 표시되고 사용자로서 사이트를 둘러볼 수 있을 것입니다.

<Browser url="http://k8s-ui-uinlb-a9797f0f61.elb.us-west-2.amazonaws.com">
<img src={require('@site/static/img/sample-app-screens/home.webp').default}/>
</Browser>