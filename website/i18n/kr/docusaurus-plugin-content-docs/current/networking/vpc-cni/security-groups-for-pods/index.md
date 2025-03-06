---
title: "파드를 위한 보안 그룹"
sidebar_position: 20
weight: 10
sidebar_custom_props: { "module": true }
description: "Amazon EC2 보안 그룹을 통해 Amazon Elastic Kubernetes Service(EKS)의 파드에 대한 인바운드 및 아웃바운드 트래픽을 제어합니다."
---

::required-time

:::tip 시작하기 전에
이 섹션을 위해 환경을 준비하세요:

```bash timeout=900 wait=30
$ prepare-environment networking/securitygroups-for-pods
```

이는 실습 환경에 다음과 같은 변경사항을 적용합니다:

- Amazon Relational Database Service 인스턴스 생성
- RDS 인스턴스에 대한 접근을 허용하는 Amazon EC2 보안 그룹 생성

이러한 변경사항을 적용하는 Terraform 코드는 [여기](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/networking/securitygroups-for-pods/.workshop/terraform)에서 확인할 수 있습니다.

:::

보안 그룹은 인스턴스 수준의 네트워크 방화벽 역할을 하며, AWS 클라우드 배포에서 가장 중요하고 일반적으로 사용되는 구성 요소 중 하나입니다. 컨테이너화된 애플리케이션은 종종 클러스터 내에서 실행되는 다른 서비스뿐만 아니라 Amazon Relational Database Service(Amazon RDS) 또는 Amazon ElastiCache와 같은 외부 AWS 서비스에 대한 접근이 필요합니다. AWS에서는 서비스 간의 네트워크 수준 접근 제어가 주로 EC2 보안 그룹을 통해 이루어집니다.

기본적으로 Amazon VPC CNI는 노드의 기본 ENI와 연결된 보안 그룹을 사용합니다. 더 구체적으로, 인스턴스와 연결된 모든 ENI는 동일한 EC2 보안 그룹을 가지게 됩니다. 따라서 노드의 모든 파드는 해당 노드가 가진 것과 동일한 보안 그룹을 공유합니다. 파드를 위한 보안 그룹을 사용하면 서로 다른 네트워크 보안 요구사항을 가진 애플리케이션들을 공유 컴퓨팅 리소스에서 실행하면서 네트워크 보안 규정 준수를 쉽게 달성할 수 있습니다. 파드 간 및 파드와 외부 AWS 서비스 간의 트래픽에 대한 네트워크 보안 규칙을 EC2 보안 그룹에서 한 번에 정의하고, Kubernetes 네이티브 API를 통해 애플리케이션에 적용할 수 있습니다. 파드 수준에서 보안 그룹을 적용한 후에는 아래와 같이 애플리케이션과 노드 그룹 아키텍처를 단순화할 수 있습니다.

VPC CNI에서 `ENABLE_POD_ENI=true`를 설정하여 파드용 보안 그룹을 활성화할 수 있습니다. Pod ENI를 활성화하면, 컨트롤 플레인에서 실행되는 [VPC Resource 컨트롤러](https://github.com/aws/amazon-vpc-resource-controller-k8s)(EKS에 의해 관리됨)가 "aws-k8s-trunk-eni"라는 트렁크 인터페이스를 생성하여 노드에 연결합니다. 트렁크 인터페이스는 인스턴스에 연결된 표준 네트워크 인터페이스 역할을 합니다.

컨트롤러는 또한 "aws-k8s-branch-eni"라는 브랜치 인터페이스를 생성하고 이를 트렁크 인터페이스와 연결합니다. 파드는 [SecurityGroupPolicy](https://github.com/aws/amazon-vpc-resource-controller-k8s/blob/master/config/crd/bases/vpcresources.k8s.aws_securitygrouppolicies.yaml) 커스텀 리소스를 사용하여 보안 그룹이 할당되고 브랜치 인터페이스와 연결됩니다. 보안 그룹은 네트워크 인터페이스와 함께 지정되므로, 이제 특정 보안 그룹이 필요한 파드를 이러한 추가 네트워크 인터페이스에 스케줄링할 수 있습니다. 권장 사항은 [EKS 모범 사례 가이드](https://aws.github.io/aws-eks-best-practices/networking/sgpp/)를 참조하고, 배포 전제 조건은 [EKS 사용자 가이드](https://docs.aws.amazon.com/eks/latest/userguide/security-groups-for-pods.html)를 참조하세요.

![Insights](./assets/overview.webp)

이 장에서는 샘플 애플리케이션 구성 요소 중 하나를 재구성하여 외부 네트워크 리소스에 접근하기 위해 파드용 보안 그룹을 활용하는 방법을 알아보겠습니다.