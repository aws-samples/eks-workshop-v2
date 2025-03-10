---
title: "AWS Secrets Manager로 시크릿 관리하기"
sidebar_position: 420
sidebar_custom_props: { "module": true }
description: "AWS Secrets Manager를 사용하여 Amazon Elastic Kubernetes Service(EKS)에서 실행되는 애플리케이션에 자격 증명과 같은 민감한 구성을 제공합니다."
---

::required-time

:::tip 시작하기 전에
이 섹션을 위해 환경을 준비하세요:

```bash timeout=600 wait=30 hook=install
$ prepare-environment security/secrets-manager
```

이는 실습 환경에 다음과 같은 변경사항을 적용합니다:

EKS 클러스터에 다음 Kubernetes 애드온을 설치합니다:

- Kubernetes Secrets Store CSI Driver
- AWS Secrets and Configuration Provider
- External Secrets Operator

이러한 변경사항을 적용하는 Terraform 코드는 [여기](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/security/secrets-manager/.workshop/terraform)에서 확인할 수 있습니다.

:::

[AWS Secrets Manager](https://aws.amazon.com/secrets-manager/)는 자격 증명, API 키, 인증서를 포함한 민감한 데이터를 쉽게 교체, 관리 및 검색할 수 있게 해주는 서비스입니다. [AWS Secrets and Configuration Provider (ASCP)](https://github.com/aws/secrets-store-csi-driver-provider-aws)를 [Kubernetes Secrets Store CSI Driver](https://secrets-store-csi-driver.sigs.k8s.io/)와 함께 사용하면 Secrets Manager에 저장된 시크릿을 Kubernetes Pod의 볼륨으로 마운트할 수 있습니다.

ASCP를 사용하면 Amazon EKS에서 실행되는 워크로드가 IAM 역할과 정책을 사용한 세분화된 접근 제어를 통해 Secrets Manager에 저장된 시크릿에 접근할 수 있습니다. Pod가 시크릿에 대한 접근을 요청하면, ASCP는 Pod의 신원을 확인하고 이를 IAM 역할로 교환한 다음, 해당 역할을 맡아 Secrets Manager에서 해당 역할에 승인된 시크릿만 검색합니다.

AWS Secrets Manager를 Kubernetes와 통합하는 대체 방법으로는 [External Secrets](https://external-secrets.io/)가 있습니다. 이 오퍼레이터는 AWS Secrets Manager의 시크릿을 Kubernetes 시크릿으로 동기화하며, 추상화 계층을 통해 전체 수명 주기를 관리합니다. Secrets Manager의 값을 Kubernetes 시크릿에 자동으로 주입합니다.

두 접근 방식 모두 Secrets Manager를 통한 자동 시크릿 교체를 지원합니다. External Secrets를 사용할 때는 업데이트를 확인하기 위한 새로 고침 간격을 구성할 수 있으며, Secrets Store CSI Driver는 Pod가 항상 최신 시크릿 값을 가지도록 하는 교체 조정 기능을 제공합니다.

다음 섹션에서는 ASCP와 External Secrets를 사용하여 AWS Secrets Manager로 시크릿을 관리하는 실제 예제를 살펴보겠습니다.