---
title: "Amazon EKS Pod Identity"
sidebar_position: 30
sidebar_custom_props: { "module": true }
description: "Amazon Elastic Kubernetes Service에서 실행되는 애플리케이션을 위한 AWS 자격 증명을 EKS Pod Identity로 관리합니다."
tmdTranslationSourceHash: eb2653bc6911d2ddc5130a39bfbf6fa2
---

::required-time

:::tip 시작하기 전에
이 섹션을 위한 환경을 준비합니다:

```bash timeout=300 wait=30
$ prepare-environment security/eks-pod-identity
```

이 명령은 실습 환경에 다음과 같은 변경 사항을 적용합니다:

- Amazon DynamoDB 테이블 생성
- AmazonEKS 워크로드가 DynamoDB 테이블에 액세스할 수 있는 IAM role 생성
- Amazon EKS 클러스터에 AWS Load Balancer Controller 설치

이러한 변경 사항을 적용하는 Terraform은 [여기](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/security/eks-pod-identity/.workshop/terraform)에서 확인할 수 있습니다.

:::

Pod의 컨테이너에 있는 애플리케이션은 지원되는 AWS SDK 또는 AWS CLI를 사용하여 AWS Identity and Access Management (IAM) 권한을 사용해 AWS 서비스에 API 요청을 할 수 있습니다. 예를 들어, 애플리케이션이 S3 버킷에 파일을 업로드하거나 DynamoDB 테이블을 쿼리해야 할 수 있으며, 이를 위해 AWS API 요청에 AWS 자격 증명으로 서명해야 합니다. [EKS Pod Identities](https://docs.aws.amazon.com/eks/latest/userguide/pod-identities.html)는 Amazon EC2 Instance Profile이 인스턴스에 자격 증명을 제공하는 방식과 유사하게 애플리케이션의 자격 증명을 관리하는 기능을 제공합니다. AWS 자격 증명을 생성하고 컨테이너에 배포하거나 Amazon EC2 인스턴스의 role을 사용하는 대신, IAM role을 Kubernetes Service Account와 연결하고 Pod가 이를 사용하도록 구성할 수 있습니다. 지원되는 정확한 SDK 버전 목록은 EKS 문서 [여기](https://docs.aws.amazon.com/eks/latest/userguide/pod-id-minimum-sdk.html)에서 확인하세요.

이 모듈에서는 샘플 애플리케이션 컴포넌트 중 하나를 AWS API를 활용하도록 재구성하고 적절한 권한을 제공하겠습니다.

