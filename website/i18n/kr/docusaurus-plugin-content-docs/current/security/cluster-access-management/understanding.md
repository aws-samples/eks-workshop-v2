---
title: "클러스터 접근 관리 API 이해하기"
sidebar_position: 11
---

Amazon EKS 클러스터를 생성할 때마다 플랫폼에서 리소스를 사용하고 관리하는 팀이나 사용자에게 접근 권한을 제공해야 합니다. 또한 각 팀은 특정 수준의 접근 권한이 필요합니다. 예를 들어 플랫폼 엔지니어는 리소스를 관리하고, 애드온을 배포하거나 문제를 해결하기 위해 클러스터 전체 접근 권한이 필요할 수 있으며, 개발자의 경우 읽기 전용 접근 권한이나 애플리케이션이 있는 네임스페이스로 제한된 관리자 접근 권한으로 충분할 수 있습니다.

어떤 경우든 Amazon EKS 클러스터에 대한 접근을 제어하기 위해 해당 팀이나 사용자와 연결된 ID나 주체에 대한 중앙 집중식 인증(AuthN)을 제공하는 도구가 필요합니다. 또한 이 도구는 최소 권한 원칙에 따라 각 팀에게 필요한 특정 권한 부여(AuthZ) 수준을 더 세분화된 방식으로 부여하기 위해 Kubernetes 역할 기반 접근 제어(RBAC)와 통합되어야 합니다.

클러스터 접근 관리 API는 Amazon EKS v1.23 이상 클러스터(신규 또는 기존)에서 사용할 수 있는 AWS API의 기능입니다. AWS IAM과 Kubernetes RBAC 간의 ID 매핑을 단순화하여 접근 관리를 위해 AWS와 Kubernetes API를 전환할 필요가 없으며 운영 부담을 줄입니다. 또한 이 도구를 통해 클러스터 관리자는 클러스터를 생성하는 데 사용된 AWS IAM 주체에게 자동으로 부여된 cluster-admin 권한을 취소하거나 세분화할 수 있습니다.

클러스터 접근 관리 API는 두 가지 기본 개념에 의존합니다:

- **접근 항목(인증)**: Amazon EKS 클러스터에 인증할 수 있는 AWS IAM 주체(사용자 또는 역할)와 직접 연결된 클러스터 ID입니다. 접근 항목은 클러스터에 바인딩되므로 클러스터가 생성되고 클러스터 접근 관리 API를 인증 방법으로 사용하도록 설정되지 않는 한 해당 클러스터에 대한 접근 항목이 존재하지 않습니다.
- **접근 정책(권한 부여)**: Amazon EKS 클러스터에서 작업을 수행하기 위한 접근 항목의 권한을 제공하는 Amazon EKS 특정 정책입니다. 접근 정책은 계정 기반 리소스이므로 클러스터가 배포되지 않은 경우에도 AWS 계정에 존재합니다.
  현재 Amazon EKS는 몇 가지 사전 정의된 AWS 관리형 정책만 지원합니다. 접근 정책은 IAM 엔터티가 아니며 기본 Kubernetes 클러스터 역할을 기반으로 Amazon EKS에 의해 정의되고 관리되며 다음과 같이 매핑됩니다.

| 접근 정책 | RBAC | 설명 |
| --------------------------- | --------------- | --------------------------------------------------------------------------------------------------------------------- |
| AmazonEKSClusterAdminPolicy | `cluster-admin` | 클러스터에 대한 관리자 접근 권한 부여 |
| AmazonEKSAdminPolicy | `admin` | 대부분의 리소스에 대한 권한 부여, 일반적으로 네임스페이스로 범위가 지정됨 |
| AmazonEKSAdminViewPolicy | `view` | 시크릿을 포함한 모든 리소스를 나열/조회할 수 있는 권한 부여. 기본적으로 클러스터 전체 범위의 조회 정책 |
| AmazonEKSEditPolicy | `edit` | 대부분의 Kubernetes 리소스를 편집할 수 있는 권한 부여, 일반적으로 네임스페이스로 범위가 지정됨 |
| AmazonEKSViewPolicy | `view` | 대부분의 Kubernetes 리소스를 나열/조회할 수 있는 권한 부여, 일반적으로 네임스페이스로 범위가 지정됨 |
| AmazonEMRJobPolicy | N/A | Amazon EKS 클러스터에서 Amazon EMR 작업을 실행하기 위한 사용자 지정 접근 권한 |

계정에서 사용 가능한 접근 정책 목록을 확인하려면 다음 명령을 실행하십시오:

```bash
$ aws eks list-access-policies

{
    "accessPolicies": [
        {
            "name": "AmazonEKSAdminPolicy",
            "arn": "arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminPolicy"
        },
        {
            "name": "AmazonEKSAdminViewPolicy",
            "arn": "arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminViewPolicy"
        },
        {
            "name": "AmazonEKSClusterAdminPolicy",
            "arn": "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
        },
        {
            "name": "AmazonEKSEditPolicy",
            "arn": "arn:aws:eks::aws:cluster-access-policy/AmazonEKSEditPolicy"
        },
        {
            "name": "AmazonEKSViewPolicy",
            "arn": "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy"
        },
        {
            "name": "AmazonEMRJobPolicy",
            "arn": "arn:aws:eks::aws:cluster-access-policy/AmazonEMRJobPolicy"
        }
    ]
}
```

앞서 설명한 대로 클러스터 접근 관리 API는 API 서버 요청에 대한 Kubernetes 권한 부여 결정에서 허용 및 통과(거부는 불가)를 지원하는 접근 정책과 업스트림 RBAC의 조합을 허용합니다. 업스트림 RBAC와 Amazon EKS 권한 부여자 모두 요청 평가의 결과를 결정할 수 없을 때 거부 결정이 발생합니다.

아래 다이어그램은 AWS IAM 주체에 대한 Amazon EKS 클러스터의 인증 및 권한 부여를 제공하기 위해 클러스터 접근 관리 API가 따르는 워크플로우를 보여줍니다.

![CAM 인증 워크플로우](./assets/cam-workflow.webp)