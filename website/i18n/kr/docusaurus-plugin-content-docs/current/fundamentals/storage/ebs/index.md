---
title: Amazon EBS
sidebar_position: 30
sidebar_custom_props: { "module": true }
description: "Amazon Elastic Block Store를 사용하여 Amazon Elastic Kubernetes Service(EKS)의 워크로드를 위한 고성능 블록 스토리지."
---
::required-time

:::tip 시작하기 전에
이 섹션을 위한 환경을 준비하세요:

```bash
$ prepare-environment fundamentals/storage/ebs
```

다음과 같은 변경사항이 실습 환경에 적용됩니다:

* EBS CSI 드라이버 애드온에 필요한 IAM 역할 생성

[여기](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/fundamentals/storage/ebs/.workshop/terraform)에서 이러한 변경사항을 적용하는 Terraform을 확인할 수 있습니다.

:::

[Amazon Elastic Block Store](https://aws.amazon.com/ebs/)는 사용하기 쉽고, 확장 가능하며, 고성능의 블록 스토리지 서비스입니다. 사용자에게 영구 볼륨(비휘발성 스토리지)을 제공합니다. 영구 스토리지를 통해 사용자는 데이터를 삭제하기로 결정할 때까지 데이터를 저장할 수 있습니다.

이 실습에서는 다음 개념들을 학습할 것입니다:

* Kubernetes StatefulSets
* EBS CSI 드라이버
* EBS 볼륨을 사용한 StatefulSet
