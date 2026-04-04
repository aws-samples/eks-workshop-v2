---
title: "로드 밸런서 생성하기"
sidebar_position: 20
tmdTranslationSourceHash: '10d2bea65be51068244e993bee3c0d60'
---

다음 구성으로 로드 밸런서를 프로비저닝하는 추가 Service를 생성해보겠습니다:

::yaml{file="manifests/modules/exposing/load-balancer/nlb/nlb.yaml" paths="spec.type,spec.ports,spec.selector"}

1. 이 `Service`는 Network Load Balancer를 생성합니다
2. NLB는 포트 80에서 수신 대기하고 연결을 포트 8080의 `ui` Pod로 전달합니다
3. 여기서 Pod의 레이블을 사용하여 이 서비스의 타겟으로 추가될 Pod를 표현합니다

이 구성을 적용하세요:

```bash timeout=180 hook=add-lb hookTimeout=430
$ kubectl apply -k ~/environment/eks-workshop/modules/exposing/load-balancer/nlb
```

`ui` 애플리케이션의 Service 리소스를 다시 검사해보겠습니다:

```bash
$ kubectl get service -n ui
NAME     TYPE           CLUSTER-IP      EXTERNAL-IP                                                            PORT(S)        AGE
ui       ClusterIP      172.16.69.215   <none>                                                                 80/TCP         7m38s
ui-nlb   LoadBalancer   172.16.77.201   k8s-ui-uinlb-e1c1ebaeb4-28a0d1a388d43825.elb.us-west-2.amazonaws.com   80:30549/TCP   105s
```

두 개의 별도 리소스가 표시되며, 새로운 `ui-nlb` 항목은 `LoadBalancer` 타입입니다. 가장 중요한 것은 "external IP" 값이 있다는 것인데, 이것은 Kubernetes 클러스터 외부에서 애플리케이션에 접근하는 데 사용할 수 있는 DNS 항목입니다.

NLB가 프로비저닝되고 타겟을 등록하는 데 몇 분이 걸리므로 컨트롤러가 생성한 로드 밸런서 리소스를 검사하는 시간을 가져보세요.

먼저 로드 밸런서 자체를 살펴보세요:

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

이것이 알려주는 내용은 무엇인가요?

- NLB는 공용 인터넷을 통해 접근 가능합니다
- VPC의 퍼블릭 서브넷을 사용합니다

또한 컨트롤러가 생성한 타겟 그룹의 타겟을 검사할 수 있습니다:

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

위의 출력은 EC2 인스턴스 ID(`i-`)를 사용하여 로드 밸런서에 등록된 3개의 타겟이 있으며 각각 동일한 포트를 사용하고 있음을 보여줍니다. 이는 기본적으로 AWS Load Balancer Controller가 "instance mode"로 작동하기 때문인데, 이는 EKS 클러스터의 워커 노드로 트래픽을 타겟팅하고 `kube-proxy`가 개별 Pod로 트래픽을 전달할 수 있도록 합니다.

다음 링크를 클릭하여 콘솔에서 NLB를 검사할 수도 있습니다:

<ConsoleButton url="https://console.aws.amazon.com/ec2/home#LoadBalancers:tag:service.k8s.aws/stack=ui/ui-nlb;sort=loadBalancerName" service="ec2" label="EC2 콘솔 열기"/>

Service 리소스에서 URL을 가져오세요:

```bash
$ ADDRESS=$(kubectl get service -n ui ui-nlb -o jsonpath="{.status.loadBalancer.ingress[*].hostname}")
$ echo "http://${ADDRESS}"
http://k8s-ui-uinlb-e1c1ebaeb4-28a0d1a388d43825.elb.us-west-2.amazonaws.com
```

로드 밸런서의 프로비저닝이 완료될 때까지 기다리려면 다음 명령을 실행할 수 있습니다:

```bash
$ curl --head -X GET --retry 30 --retry-all-errors --retry-delay 15 --connect-timeout 30 --max-time 60 \
  -k $(kubectl get service -n ui ui-nlb -o jsonpath="{.status.loadBalancer.ingress[*].hostname}")
```

이제 애플리케이션이 외부 세계에 노출되었으므로 웹 브라우저에 해당 URL을 붙여넣어 접속해보겠습니다. 웹 스토어의 UI가 표시되며 사용자로서 사이트를 탐색할 수 있습니다.

<Browser url="http://k8s-ui-uinlb-e1c1ebaeb4-28a0d1a388d43825.elb.us-west-2.amazonaws.com">
<img src={require('@site/static/img/sample-app-screens/home.webp').default}/>
</Browser>

