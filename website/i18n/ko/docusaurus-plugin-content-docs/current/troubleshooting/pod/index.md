---
title: "Pod 문제"
sidebar_position: 70
description: "Amazon EKS 클러스터의 일반적인 Pod 문제 해결"
sidebar_custom_props: { "module": true }
tmdTranslationSourceHash: cc02606a7744b93a170d26c503247f1c
---

::required-time

이 섹션에서는 Amazon EKS 클러스터에서 컨테이너화된 애플리케이션이 실행되는 것을 방해하는 가장 일반적인 Pod 문제들을 해결하는 방법을 배웁니다. 예를 들어 ImagePullBackOff와 ContainerCreating 상태에서 멈추는 문제 등이 있습니다.

:::tip 시작하기 전에
이 섹션을 위한 환경을 준비합니다:

```bash timeout=600 wait=300
$ prepare-environment troubleshooting/pod
```

Terraform이 적용하는 변경 사항은 [여기](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/troubleshooting/pod/.workshop/terraform)에서 확인할 수 있습니다.

:::
:::info
실습 환경 준비에는 몇 분 정도 소요될 수 있으며, 다음과 같은 변경사항이 적용됩니다:

- retail-sample-app-ui라는 이름의 ECR 리포지토리를 생성합니다.
- EC2 인스턴스를 생성하고 해당 인스턴스에서 0.4.0 태그를 사용하여 retail store 샘플 앱 이미지를 ECR 리포지토리에 푸시합니다.
- default 네임스페이스에 ui-private라는 이름의 새 배포를 생성합니다.
- default 네임스페이스에 ui-new라는 이름의 새 배포를 생성합니다.
- EKS 클러스터에 aws-efs-csi-driver 애드온을 설치합니다.
- EFS 파일시스템과 마운트 타겟을 생성합니다.
- 이러한 유형의 문제를 해결하는 방법을 배울 수 있도록 배포 스펙에 문제를 의도적으로 발생시킵니다.
- 이러한 유형의 문제들을 해결하는 방법을 배울 수 있도록 배포 스펙에 문제를 의도적으로 발생시킵니다.
- default 네임스페이스에 EFS를 persistent volume로 활용하기 위해 efs-claim이라는 persistent volume claim으로 지원되는 efs-app이라는 이름의 배포를 생성합니다.

:::

