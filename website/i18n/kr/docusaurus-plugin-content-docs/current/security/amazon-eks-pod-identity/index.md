---
title: "Amazon EKS Pod Identity"
sidebar_position: 30
sidebar_custom_props: { "module": true }
description: "Amazon Elastic Kubernetes Service(EKS)에서 실행되는 애플리케이션의 AWS 자격 증명을 EKS Pod Identity로 관리하기"
---

::required-time

:::tip 시작하기 전에
이 섹션을 위해 환경을 준비하세요:

```bash timeout=300 wait=30
$ prepare-environment security/eks-pod-identity
```

이는 실습 환경에 다음과 같은 변경사항을 적용합니다:

- Amazon DynamoDB 테이블 생성
- DynamoDB 테이블에 접근하기 위한 AmazonEKS 워크로드용 IAM 역할 생성
- EKS Pod Identity Agent를 위한 EKS 관리형 애드온 설치
- Amazon EKS 클러스터에 AWS Load Balancer 컨트롤러 설치

이러한 변경사항을 적용하는 Terraform 코드는 [여기](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/security/eks-pod-identity/.workshop/terraform)에서 확인할 수 있습니다.

:::

Pod의 컨테이너에 있는 애플리케이션은 지원되는 AWS SDK나 AWS CLI를 사용하여 AWS Identity and Access Management(IAM) 권한으로 AWS 서비스에 API 요청을 할 수 있습니다. 예를 들어, 애플리케이션이 S3 버킷에 파일을 업로드하거나 DynamoDB 테이블을 쿼리해야 할 수 있으며, 이를 위해서는 AWS API 요청에 AWS 자격 증명으로 서명해야 합니다. [EKS Pod Identities](https://docs.aws.amazon.com/eks/latest/userguide/pod-identities.html)는 Amazon EC2 인스턴스 프로파일이 인스턴스에 자격 증명을 제공하는 방식과 유사하게 애플리케이션의 자격 증명을 관리할 수 있는 기능을 제공합니다. AWS 자격 증명을 컨테이너에 생성하고 배포하거나 Amazon EC2 인스턴스의 역할을 사용하는 대신, IAM 역할을 Kubernetes 서비스 계정과 연결하고 이를 사용하도록 Pod를 구성할 수 있습니다. 지원되는 버전의 정확한 목록은 [여기](https://docs.aws.amazon.com/eks/latest/userguide/pod-id-minimum-sdk.html)에서 EKS 문서를 확인하세요.

이 장에서는 샘플 애플리케이션 구성 요소 중 하나를 AWS API를 활용하도록 재구성하고 적절한 권한을 제공할 것입니다.