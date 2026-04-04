---
title: "Pod 검사하기"
sidebar_position: 50
tmdTranslationSourceHash: 30800eaa2f30899dfc6709dc0747f890
---

이제 catalog Pod가 실행 중이고 Amazon RDS 데이터베이스를 성공적으로 사용하고 있으므로, Security Groups for Pods와 관련된 어떤 신호가 있는지 자세히 살펴보겠습니다.

가장 먼저 할 수 있는 것은 Pod의 어노테이션을 확인하는 것입니다:

```bash
$ kubectl get pod -n catalog -l app.kubernetes.io/component=service -o yaml \
  | yq '.items[0].metadata.annotations'
kubernetes.io/psp: eks.privileged
prometheus.io/path: /metrics
prometheus.io/port: "8080"
prometheus.io/scrape: "true"
vpc.amazonaws.com/pod-eni: '[{"eniId":"eni-0eb4769ea066fa90c","ifAddress":"02:23:a2:af:a2:1f","privateIp":"10.42.10.154","vlanId":2,"subnetCidr":"10.42.10.0/24"}]'
```

`vpc.amazonaws.com/pod-eni` 어노테이션은 이 Pod에 사용된 브랜치 ENI에 대한 메타데이터를 보여줍니다. 여기에는 ID, MAC 주소, 프라이빗 IP 주소, 서브넷 CIDR이 포함됩니다.

Kubernetes 이벤트도 우리가 추가한 구성에 대한 응답으로 VPC 리소스 컨트롤러가 조치를 취하는 것을 보여줍니다:

```bash
$ kubectl get events -n catalog | grep SecurityGroupRequested
5m         Normal    SecurityGroupRequested   pod/catalog-6ccc6b5575-w2fvm    Pod will get the following Security Groups [sg-037ec36e968f1f5e7]
```

:::info
VPC Resource Controller는 브랜치 네트워크 인터페이스의 수명 주기를 관리하고, 이를 Pod에 연결하며, 보안 그룹을 연결하는 역할을 담당합니다.
:::

AWS 콘솔에서 VPC 리소스 컨트롤러가 관리하는 ENI를 볼 수도 있습니다:

<ConsoleButton url="https://console.aws.amazon.com/ec2/home#NIC:v=3;tag:eks:eni:owner=eks-vpc-resource-controller;tag:vpcresources.k8s.aws/trunk-eni-id=:eni" service="ec2" label="EC2 콘솔 열기"/>

이를 통해 할당된 보안 그룹과 같은 브랜치 ENI에 대한 정보를 볼 수 있습니다. 이러한 브랜치 ENI는 트런크 인터페이스와 연결되어 있으며 특정 Pod 전용으로 사용되어 Pod 수준에서 세밀한 네트워크 보안 제어를 가능하게 합니다.

