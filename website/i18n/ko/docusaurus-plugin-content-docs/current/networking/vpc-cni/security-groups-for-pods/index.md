---
title: "Pod용 보안 그룹"
sidebar_position: 20
weight: 10
sidebar_custom_props: { "module": true }
description: "Amazon EC2 보안 그룹을 사용하여 Amazon Elastic Kubernetes Service의 Pod로 들어오고 나가는 트래픽을 제어합니다."
tmdTranslationSourceHash: '2e744b7e7ed933443ac0a65be866b7fb'
---

::required-time

:::tip 시작하기 전에
이 섹션을 위한 환경을 준비합니다:

```bash timeout=900 wait=30
$ prepare-environment networking/securitygroups-for-pods
```

이 명령은 실습 환경에 다음과 같은 변경 사항을 적용합니다:

- Amazon Relational Database Service 인스턴스 생성
- RDS 인스턴스에 대한 액세스를 허용하는 Amazon EC2 보안 그룹 생성

이러한 변경 사항을 적용하는 Terraform은 [여기](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/networking/securitygroups-for-pods/.workshop/terraform)에서 확인할 수 있습니다.

:::

인스턴스 레벨 네트워크 방화벽 역할을 하는 보안 그룹은 모든 AWS 클라우드 배포에서 가장 중요하고 일반적으로 사용되는 구성 요소 중 하나입니다. 컨테이너화된 애플리케이션은 클러스터 내에서 실행되는 다른 서비스뿐만 아니라 Amazon Relational Database Service(Amazon RDS) 또는 Amazon ElastiCache와 같은 외부 AWS 서비스에 액세스해야 하는 경우가 많습니다. AWS에서 서비스 간의 네트워크 레벨 액세스를 제어하는 것은 주로 EC2 보안 그룹을 통해 이루어집니다.

기본적으로 Amazon VPC CNI는 노드의 기본 ENI와 연결된 보안 그룹을 사용합니다. 보다 구체적으로, 인스턴스와 연결된 모든 ENI는 동일한 EC2 보안 그룹을 갖습니다. 따라서 노드의 모든 Pod는 노드가 실행되는 것과 동일한 보안 그룹을 공유합니다. Pod용 보안 그룹은 공유 컴퓨팅 리소스에서 다양한 네트워크 보안 요구 사항을 가진 애플리케이션을 실행하여 네트워크 보안 규정 준수를 쉽게 달성할 수 있게 해줍니다. Pod 간 및 Pod와 외부 AWS 서비스 간의 트래픽에 걸친 네트워크 보안 규칙을 EC2 보안 그룹을 사용하여 한 곳에서 정의하고 Kubernetes 네이티브 API를 통해 애플리케이션에 적용할 수 있습니다. Pod 레벨에서 보안 그룹을 적용하면 아래와 같이 애플리케이션 및 노드 그룹 아키텍처를 단순화할 수 있습니다.

VPC CNI에 `ENABLE_POD_ENI=true`를 설정하여 Pod용 보안 그룹을 활성화할 수 있습니다. Pod ENI를 활성화하면 (EKS가 관리하는) 컨트롤 플레인에서 실행되는 [VPC Resource Controller](https://github.com/aws/amazon-vpc-resource-controller-k8s)가 "aws-k8s-trunk-eni"라는 트랭크 인터페이스를 생성하고 노드에 연결합니다. 트랭크 인터페이스는 인스턴스에 연결된 표준 네트워크 인터페이스로 작동합니다.

컨트롤러는 또한 "aws-k8s-branch-eni"라는 브랜치 인터페이스를 생성하고 트랭크 인터페이스와 연결합니다. Pod는 [SecurityGroupPolicy](https://github.com/aws/amazon-vpc-resource-controller-k8s/blob/master/config/crd/bases/vpcresources.k8s.aws_securitygrouppolicies.yaml) 사용자 정의 리소스를 사용하여 보안 그룹이 할당되고 브랜치 인터페이스와 연결됩니다. 보안 그룹은 네트워크 인터페이스와 함께 지정되므로 이제 특정 보안 그룹이 필요한 Pod를 이러한 추가 네트워크 인터페이스에 스케줄링할 수 있습니다. 권장 사항은 [EKS 모범 사례 가이드](https://aws.github.io/aws-eks-best-practices/networking/sgpp/)를 검토하고 배포 전제 조건은 [EKS 사용자 가이드](https://docs.aws.amazon.com/eks/latest/userguide/security-groups-for-pods.html)를 참조하세요.

![Insights](/docs/networking/vpc-cni/security-groups-for-pods/overview.webp)

이 장에서는 샘플 애플리케이션 구성 요소 중 하나를 재구성하여 Pod용 보안 그룹을 활용하여 외부 네트워크 리소스에 액세스합니다.

