---
title: "IAM Roles for Service Accounts"
sidebar_position: 20
sidebar_custom_props: { "module": true }
description: "IAM Roles for Service Accounts를 사용하여 Amazon Elastic Kubernetes Service에서 실행되는 애플리케이션의 AWS 자격 증명을 관리합니다."
tmdTranslationSourceHash: '315131c1bce2a477ebe6a119db922ace'
---

::required-time

:::tip 시작하기 전에
이 섹션을 위한 환경을 준비합니다:

```bash timeout=300 wait=30
$ prepare-environment security/irsa
```

이 명령은 랩 환경에 다음과 같은 변경 사항을 적용합니다:

- Amazon DynamoDB 테이블 생성
- DynamoDB 테이블에 액세스할 수 있는 Amazon EKS 워크로드용 IAM role 생성
- Amazon EKS 클러스터에 AWS Load Balancer Controller 설치

이러한 변경 사항을 적용하는 Terraform은 [여기](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/security/irsa/.workshop/terraform)에서 확인할 수 있습니다.

:::

Pod의 컨테이너에 있는 애플리케이션은 AWS SDK 또는 AWS CLI를 사용하여 AWS Identity and Access Management (IAM) 권한을 사용하는 AWS 서비스에 API 요청을 할 수 있습니다. 예를 들어, 애플리케이션은 S3 버킷에 파일을 업로드하거나 DynamoDB 테이블을 쿼리해야 할 수 있습니다. 이를 위해 애플리케이션은 AWS 자격 증명으로 AWS API 요청에 서명해야 합니다. [IAM Roles for Service Accounts](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html) (IRSA)는 IAM Instance Profile이 Amazon EC2 인스턴스에 자격 증명을 제공하는 것과 유사한 방식으로 애플리케이션의 자격 증명을 관리하는 기능을 제공합니다. AWS 자격 증명을 생성하고 컨테이너에 배포하거나 권한 부여를 위해 Amazon EC2 Instance Profile에 의존하는 대신, IAM role을 Kubernetes Service Account와 연결하고 해당 Service Account를 사용하도록 Pod를 구성할 수 있습니다.

이 챕터에서는 샘플 애플리케이션 구성 요소 중 하나를 AWS API를 활용하도록 재구성하고 적절한 인증을 제공합니다.

