---
title: Amazon EFS
sidebar_position: 30
sidebar_custom_props: { "module": true }
description: "Amazon Elastic File System을 사용하여 Amazon Elastic Kubernetes Service의 워크로드를 위한 서버리스, 완전 탄력적 파일 스토리지"
tmdTranslationSourceHash: '9933fa49f44d9f120280c54b2bb9af48'
---

::required-time

:::tip 시작하기 전에
이 섹션을 위한 환경을 준비합니다:

```bash timeout=300 wait=30
$ prepare-environment fundamentals/storage/efs
```

이 명령은 실습 환경에 다음과 같은 변경사항을 적용합니다:

- Amazon EFS CSI 드라이버를 위한 IAM 역할 생성
- Amazon EFS 파일 시스템 생성

이러한 변경사항을 적용하는 Terraform은 [여기](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/fundamentals/storage/ebs/.workshop/terraform)에서 확인할 수 있습니다.

:::

[Amazon Elastic File System](https://docs.aws.amazon.com/efs/latest/ug/whatisefs.html) (Amazon EFS)은 애플리케이션을 중단하지 않고 페타바이트 규모까지 자동으로 확장되는 서버리스, 완전 탄력적 파일 시스템을 제공합니다. 파일을 추가하거나 제거할 때 용량을 프로비저닝하고 관리할 필요가 없어 AWS 클라우드 서비스 및 온프레미스 리소스와 함께 사용하기에 이상적입니다.

이 실습에서는 다음을 수행합니다:

- 영구 네트워크 스토리지에 대해 학습
- Kubernetes용 EFS CSI 드라이버를 구성하고 배포
- Kubernetes 배포에서 EFS를 사용한 동적 프로비저닝 구현

이 실습 경험을 통해 확장 가능한 영구 스토리지 솔루션을 위해 Amazon EKS와 함께 Amazon EFS를 효과적으로 사용하는 방법을 시연합니다.

