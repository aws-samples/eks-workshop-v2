---
title: Amazon FSx for OpenZFS
sidebar_position: 40
sidebar_custom_props: { "module": true }
description: "Amazon FSx for OpenZFS를 사용하여 Amazon Elastic Kubernetes Service에서 실행되는 워크로드를 위한 완전 관리형, 고성능, 탄력적인 파일 스토리지를 제공합니다."
tmdTranslationSourceHash: '456aff728bf007f40feada9eef333db7'
---

::required-time

:::tip 시작하기 전에
이 섹션을 위한 환경을 준비하세요:

```bash timeout=900 wait=30
$ prepare-environment fundamentals/storage/fsxz
```

이 명령은 실습 환경에 다음과 같은 변경 사항을 적용합니다:

- IAM OIDC 공급자 생성
- EKS 클러스터에서 Amazon FSx for OpenZFS 파일 시스템에 액세스하는 데 필요한 규칙이 포함된 새 보안 그룹 생성
- Amazon FSx for OpenZFS Single-AZ 2 파일 시스템 생성

이러한 변경 사항을 적용하는 Terraform은 [여기](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/fundamentals/storage/fsxz/.workshop/terraform)에서 확인할 수 있습니다.

:::

[Amazon FSx for OpenZFS](https://docs.aws.amazon.com/fsx/latest/OpenZFSGuide/what-is-fsx.html)는 NFSv3 및 NFSv4를 통해 액세스할 수 있는 완전 관리형, 고성능 공유 파일 시스템을 제공합니다. 마이크로초 지연 시간으로 수백만 IOPS와 최대 21 GB/s의 처리량으로 공유 데이터 세트에 액세스할 수 있습니다. FSx for OpenZFS는 제로 공간 스냅샷, 제로 공간 클론, 데이터 복제, 씬 프로비저닝, 사용자 할당량, 압축과 같은 많은 엔터프라이즈 기능도 포함하고 있습니다.

두 가지 다른 스토리지 클래스가 있습니다: 모든 SSD 기반 스토리지 클래스와 Intelligent-Tiering 스토리지 클래스입니다. SSD 스토리지 클래스를 활용하는 파일 시스템은 일관된 마이크로초 지연 시간을 제공합니다. Intelligent-Tiering 파일 시스템은 캐시된 읽기에 대해 마이크로초 지연 시간, 쓰기에 대해 1-2밀리초 지연 시간, 읽기 캐시 미스에 대해 수십 밀리초 지연 시간을 제공합니다. Intelligent-Tiering 스토리지 클래스는 데이터 세트와 함께 증가 및 감소하는 완전히 탄력적인 스토리지 용량을 제공하며, 소비된 용량에 대해서만 S3와 유사한 가격으로 청구됩니다.

이 실습에서는 다음을 수행합니다:

- 영구 네트워크 스토리지에 대해 학습
- Kubernetes용 FSx for OpenZFS CSI 드라이버 구성 및 배포
- Kubernetes 배포에서 FSx for OpenZFS를 사용한 동적 프로비저닝 구현

이 실습 경험은 Amazon EKS와 함께 Amazon FSx for OpenZFS를 효과적으로 사용하여 완전 관리형, 고성능, 엔터프라이즈 기능을 갖춘 탄력적인 영구 스토리지 솔루션을 구현하는 방법을 보여줍니다.

