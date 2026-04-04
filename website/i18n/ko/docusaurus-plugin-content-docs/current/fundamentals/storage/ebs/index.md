---
title: Amazon EBS
sidebar_position: 30
sidebar_custom_props: { "module": true }
description: "Amazon Elastic Kubernetes Service에서 Amazon Elastic Block Store를 사용한 워크로드를 위한 고성능 블록 스토리지."
tmdTranslationSourceHash: '51097ba837433f254d6682043e2d4996'
---

::required-time

:::tip 시작하기 전에
이 섹션을 위한 환경을 준비합니다:

```bash timeout=300 wait=30
$ prepare-environment fundamentals/storage/ebs
```

이것은 실습 환경에 다음과 같은 변경 사항을 적용합니다:

- EBS CSI 드라이버 애드온에 필요한 IAM 역할 생성

이러한 변경 사항을 적용하는 Terraform은 [여기](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/fundamentals/storage/ebs/.workshop/terraform)에서 확인할 수 있습니다.

:::

[Amazon Elastic Block Store](https://aws.amazon.com/ebs/)는 사용하기 쉽고 확장 가능한 고성능 블록 스토리지 서비스입니다. 이는 사용자에게 영구 볼륨(비휘발성 스토리지)을 제공합니다. 영구 스토리지는 사용자가 데이터를 삭제하기로 결정할 때까지 데이터를 저장할 수 있게 합니다.

이 실습에서는 다음 개념에 대해 학습합니다:

- Kubernetes StatefulSet
- EBS CSI Driver
- EBS 볼륨을 사용한 StatefulSet

