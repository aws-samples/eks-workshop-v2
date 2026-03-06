---
title: Managed Node Groups
sidebar_position: 10
tmdTranslationSourceHash: 164445147875a1ed08f67c28502a8175
---

EKS 클러스터는 Pod가 스케줄링되는 하나 이상의 EC2 노드를 포함합니다. EKS 노드는 AWS 계정에서 실행되며 클러스터 API 서버 엔드포인트를 통해 클러스터의 제어 플레인에 연결됩니다. 하나 이상의 노드를 노드 그룹에 배포합니다. 노드 그룹은 EC2 Auto Scaling 그룹에 배포된 하나 이상의 EC2 인스턴스입니다.

EKS 노드는 표준 Amazon EC2 인스턴스입니다. EC2 요금에 따라 요금이 청구됩니다. 자세한 내용은 [Amazon EC2 pricing](https://aws.amazon.com/ec2/pricing/)을 참조하세요.

[Amazon EKS managed node groups](https://docs.aws.amazon.com/eks/latest/userguide/managed-node-groups.html)는 Amazon EKS 클러스터의 노드 프로비저닝 및 라이프사이클 관리를 자동화합니다. 이를 통해 새로운 AMI 또는 Kubernetes 버전 배포를 위한 롤링 업데이트와 같은 운영 작업이 크게 간소화됩니다.

![Managed Node Groups](/docs/fundamentals/compute/managed-node-groups/managed-node-groups.webp)

Amazon EKS managed node groups 실행의 장점은 다음과 같습니다:

- Amazon EKS 콘솔, `eksctl`, AWS CLI, AWS API 또는 AWS CloudFormation 및 Terraform을 포함한 Infrastructure as Code 도구를 사용하여 단일 작업으로 노드를 생성, 자동 업데이트 또는 종료할 수 있습니다
- 프로비저닝된 노드는 최신 Amazon EKS 최적화 AMI를 사용하여 실행됩니다
- MNG의 일부로 프로비저닝된 노드는 가용 영역, CPU 아키텍처 및 인스턴스 유형과 같은 메타데이터로 자동으로 태그가 지정됩니다
- 노드 업데이트 및 종료는 자동으로 그리고 gracefully하게 노드를 드레인하여 애플리케이션이 계속 사용 가능한 상태를 유지합니다
- Amazon EKS managed node groups 사용에 대한 추가 비용은 없으며 프로비저닝된 AWS 리소스에 대해서만 비용을 지불합니다

이 섹션의 실습에서는 EKS managed node groups를 사용하여 클러스터에 컴퓨팅 용량을 제공하는 다양한 방법을 다룹니다.

