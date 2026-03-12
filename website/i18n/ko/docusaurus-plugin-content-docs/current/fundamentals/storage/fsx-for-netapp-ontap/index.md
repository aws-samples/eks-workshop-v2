---
title: FSx for NetApp ONTAP
sidebar_position: 50
sidebar_custom_props: { "module": true }
description: "Amazon Elastic Kubernetes Service에서 Amazon FSx for NetApp ONTAP을 사용한 완전관리형 공유 스토리지"
tmdTranslationSourceHash: 'd91a0fa0e676536bceca6c2b324434de'
---

::required-time{estimatedLabExecutionTimeMinutes="60"}

:::caution

FSx For NetApp ONTAP 파일 시스템과 관련 인프라를 프로비저닝하는 데 최대 30분이 소요될 수 있습니다. 이 실습을 시작하기 전에 이 점을 고려하시고, `prepare-environment` 명령이 다른 실습보다 더 오래 걸릴 수 있음을 예상하시기 바랍니다.

:::

:::tip 시작하기 전에
이 섹션을 위한 환경을 준비합니다:

```bash timeout=1800 wait=30
$ prepare-environment fundamentals/storage/fsxn
```

:::

[Amazon FSx for NetApp ONTAP](https://docs.aws.amazon.com/fsx/latest/ONTAPGuide/what-is-fsx-ontap.html) (FSxN)은 클라우드에서 완전관리형 ONTAP 파일 시스템을 시작하고 실행할 수 있는 스토리지 서비스입니다. ONTAP은 NetApp의 파일 시스템 기술로, 널리 채택된 데이터 액세스 및 데이터 관리 기능을 제공합니다. Amazon FSx for NetApp ONTAP은 온프레미스 NetApp 파일 시스템의 기능, 성능 및 API를 완전관리형 AWS 서비스의 민첩성, 확장성 및 단순성과 결합하여 제공합니다.

이 실습에서는 다음을 수행합니다:

- 영구 네트워크 스토리지에 대해 학습합니다
- Kubernetes용 FSx for NetApp ONTAP CSI Driver를 구성하고 배포합니다
- Kubernetes 배포에서 FSx for NetApp ONTAP을 사용한 동적 프로비저닝을 구현합니다

이 실습을 통해 Amazon EKS에서 Amazon FSx for NetApp ONTAP을 효과적으로 사용하여 완전관리형 엔터프라이즈급 영구 스토리지 솔루션을 구현하는 방법을 실습할 수 있습니다.

