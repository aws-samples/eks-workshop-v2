---
title: "Cluster Access Management API 이해하기"
sidebar_position: 11
tmdTranslationSourceHash: 8aa7ba79d55267c9c14e17689f94ef87
---

Amazon EKS 클러스터를 생성할 때마다 플랫폼을 소비하고 관리하는 팀이나 사용자에게 액세스를 제공해야 합니다. 서로 다른 팀은 서로 다른 수준의 액세스가 필요합니다 - 플랫폼 엔지니어는 리소스를 관리하고, 애드온을 배포하거나 문제를 해결하기 위해 클러스터 전체 액세스가 필요할 수 있지만, 개발자는 읽기 전용 액세스만 필요하거나 애플리케이션이 있는 네임스페이스로 제한된 관리자 액세스만 필요할 수 있습니다.

어느 경우든, 해당 팀이나 사용자와 연결된 ID 또는 principal에 대해 중앙 집중식 인증(AuthN)을 제공하여 Amazon EKS 클러스터에 대한 액세스를 제어하는 솔루션이 필요합니다. 이 솔루션은 Kubernetes 역할 기반 액세스 제어(RBAC)와 통합되어 각 팀이 필요로 하는 특정 권한 부여(AuthZ) 수준을 보다 세밀한 방식으로 부여하여 최소 권한 원칙을 따라야 합니다.

Cluster Access Management API는 Amazon EKS v1.23 이상 클러스터(신규 및 기존 모두)에서 사용할 수 있는 AWS API의 기능입니다. 이는 AWS IAM과 Kubernetes RBAC 간의 ID 매핑을 단순화하여 액세스 관리를 위해 AWS와 Kubernetes API 간에 전환할 필요성을 제거하고 운영 오버헤드를 줄입니다. 또한 이 도구를 사용하면 클러스터 관리자가 클러스터를 생성하는 데 사용된 AWS IAM principal에 자동으로 부여된 cluster-admin 권한을 취소하거나 세분화할 수 있습니다.

Cluster Access Management API는 두 가지 기본 개념에 의존합니다:

- **Access Entries (인증)**: Amazon EKS 클러스터에 인증할 수 있는 AWS IAM principal(사용자 또는 역할)에 직접 연결된 클러스터 ID입니다. Access Entry는 클러스터에 바인딩되므로 클러스터가 생성되고 Cluster Access Management API를 인증 방법으로 사용하도록 설정되지 않으면 해당 클러스터에 대한 Access Entry가 존재하지 않습니다.
- **Access Policies (권한 부여)**: Access Entry가 Amazon EKS 클러스터에서 작업을 수행할 수 있는 권한을 제공하는 Amazon EKS 전용 정책입니다. Access Policy는 계정 기반 리소스로, AWS 계정에 클러스터가 배포되지 않았더라도 존재합니다.
  현재 Amazon EKS는 몇 가지 사전 정의된 AWS 관리형 정책만 지원합니다. Access Policy는 IAM 엔티티가 아니라 기본 Kubernetes 클러스터 역할을 기반으로 Amazon EKS에 의해 정의 및 관리되며 다음과 같이 매핑됩니다:

| Access Policy               | RBAC            | 설명                                                                |
| --------------------------- | --------------- | ------------------------------------------------------------------- |
| AmazonEKSClusterAdminPolicy | `cluster-admin` | 클러스터에 대한 관리자 액세스 권한을 부여합니다                      |
| AmazonEKSAdminPolicy        | `admin`         | 대부분의 리소스에 대한 권한을 부여하며, 일반적으로 네임스페이스로 범위가 지정됩니다 |
| AmazonEKSAdminViewPolicy    | `view`          | Secret을 포함한 클러스터의 모든 리소스를 나열/보기 위한 액세스 권한을 부여합니다 (클러스터 전체 범위의 view 정책) |
| AmazonEKSEditPolicy         | `edit`          | 대부분의 Kubernetes 리소스를 편집할 수 있는 액세스 권한을 부여하며, 일반적으로 네임스페이스로 범위가 지정됩니다 |
| AmazonEKSViewPolicy         | `view`          | 대부분의 Kubernetes 리소스를 나열/보기 위한 액세스 권한을 부여하며, 일반적으로 네임스페이스로 범위가 지정됩니다 |
| AmazonEMRJobPolicy          | N/A             | Amazon EKS 클러스터에서 Amazon EMR 작업을 실행하기 위한 사용자 지정 액세스 |

계정에서 사용 가능한 Access Policy 목록을 확인하려면 다음 명령을 실행하십시오:

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

앞서 설명한 것처럼 Cluster Access Management API는 업스트림 RBAC와 Access Policy의 조합을 허용하여 API 서버 요청에 대한 Kubernetes 권한 부여 결정에서 허용 및 통과(거부는 아님)를 지원합니다. 업스트림 RBAC와 Amazon EKS authorizer 모두 요청 평가 결과를 결정할 수 없을 때 거부 결정이 발생합니다.

아래 다이어그램은 Cluster Access Management API가 AWS IAM principal에게 Amazon EKS 클러스터에 대한 인증 및 권한 부여를 제공하기 위해 따르는 워크플로를 보여줍니다.

![CAM Auth Workflow](/docs/security/cluster-access-management/cam-workflow.webp)

