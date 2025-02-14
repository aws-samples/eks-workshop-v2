---
title: FSx For NetApp ONTAP
sidebar_position: 30
sidebar_custom_props: { "module": true }
description: "Fully managed shared storage for workloads on Amazon Elastic Kubernetes Service(EKS) with Amazon FSx for NetApp ONTAP."
---
::required-time{estimatedLabExecutionTimeMinutes="60"}

:::caution

FSx For NetApp ONTAP 파일 시스템 및 관련 인프라를 프로비저닝하는 데 최대 30분이 소요될 수 있습니다. 이 실습을 시작하기 전에 이 점을 고려해주시고, `prepare-environment` 명령이 이전에 수행했던 다른 실습들보다 더 오래 걸릴 수 있음을 예상해주세요.

:::

:::tip 시작하기 전에
이 섹션을 위한 환경을 준비하세요:

```bash
$ prepare-environment fundamentals/storage/fsxn
```

:::



[Amazon FSx for NetApp ONTAP](https://docs.aws.amazon.com/fsx/latest/ONTAPGuide/what-is-fsx-ontap.html) (FSxN)은 클라우드에서 완전 관리형 ONTAP 파일 시스템을 시작하고 실행할 수 있게 해주는 스토리지 서비스입니다. ONTAP는 널리 채택된 데이터 접근 및 데이터 관리 기능을 제공하는 NetApp의 파일 시스템 기술입니다. Amazon FSx for NetApp ONTAP는 완전 관리형 AWS 서비스의 민첩성, 확장성, 단순성과 함께 온프레미스 NetApp 파일 시스템의 기능, 성능 및 API를 제공합니다.

이 실습에서는 다음 개념들을 학습할 것입니다:

* `assets` 마이크로서비스 배포
* FSx for NetApp ONTAP CSI 드라이버
* FSx for NetApp ONTAP와 Kubernetes 배포를 사용한 동적 프로비저닝
