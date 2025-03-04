---
title: "Pod 검사하기"
sidebar_position: 50
---

이제 카탈로그 Pod가 실행 중이고 Amazon RDS 데이터베이스를 성공적으로 사용하고 있으므로, Pod용 보안 그룹과 관련된 신호가 어떤 것이 있는지 자세히 살펴보겠습니다.

먼저 Pod의 어노테이션을 확인할 수 있습니다:

```bash
$ kubectl get pod -n catalog -l app.kubernetes.io/component=service -o yaml \
  | yq '.items[0].metadata.annotations'
kubernetes.io/psp: eks.privileged
prometheus.io/path: /metrics
prometheus.io/port: "8080"
prometheus.io/scrape: "true"
vpc.amazonaws.com/pod-eni: '[{"eniId":"eni-0eb4769ea066fa90c","ifAddress":"02:23:a2:af:a2:1f","privateIp":"10.42.10.154","vlanId":2,"subnetCidr":"10.42.10.0/24"}]'
```

`vpc.amazonaws.com/pod-eni` 어노테이션은 이 Pod에 사용된 브랜치 ENI, 프라이빗 IP 주소 등과 같은 메타데이터를 보여줍니다.

Kubernetes 이벤트에서도 우리가 추가한 구성에 대응하여 VPC 리소스 컨트롤러가 취한 조치를 확인할 수 있습니다:

```bash
$ kubectl get events -n catalog | grep SecurityGroupRequested
5m         Normal    SecurityGroupRequested   pod/catalog-6ccc6b5575-w2fvm    Pod will get the following Security Groups [sg-037ec36e968f1f5e7]
```

마지막으로, 콘솔에서 VPC 리소스 컨트롤러가 관리하는 ENI를 볼 수 있습니다:

<ConsoleButton url="https://console.aws.amazon.com/ec2/home#NIC:v=3;tag:eks:eni:owner=eks-vpc-resource-controller;tag:vpcresources.k8s.aws/trunk-eni-id=:eni" service="ec2" label="EC2 콘솔 열기"/>

이를 통해 할당된 보안 그룹과 같은 브랜치 ENI에 대한 정보를 확인할 수 있습니다.