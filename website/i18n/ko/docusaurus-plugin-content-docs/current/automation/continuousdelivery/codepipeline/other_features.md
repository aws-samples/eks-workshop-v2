---
title: "CodePipeline의 기능"
sidebar_position: 40
tmdTranslationSourceHash: '0b42ba05fadc4739a6b9682cc69d0547'
---

### CodePipeline의 EKS action 기타 기능

1. **프라이빗 클러스터 지원**: 사용자는 CodePipeline EKS action에서 프라이빗 전용 액세스로 클러스터를 구성할 수 있습니다. 기본적으로 CodePipeline은 클러스터에 구성된 대로 서브넷과 보안 그룹을 사용합니다. 그러나 action 구성에서 지정하여 이를 재정의할 수 있습니다.
2. **Helm**: `kubectl` 외에도 CodePipeline EKS action을 통해 사용자는 `helm` 차트로 EKS action을 구성할 수 있습니다. 이 action은 .tgz 형식의 입력도 허용합니다. 따라서 S3 버킷에 .tgz 형식의 helm 차트가 있는 경우 압축하지 않고도 S3 버킷/키를 별도의 소스 action으로 추가하여 직접 사용할 수 있습니다.

### EKS action과 함께 사용할 수 있는 CodePipeline의 기타 CD 기능

1. **동적 변수**: CodePipeline을 사용하면 변수를 사용하여 런타임에 action에 대한 입력을 변경할 수 있습니다. CodePipeline은 action 및 파이프라인 수준 변수를 지원합니다. action 변수 값은 (이 모듈에서 볼 수 있듯이) action에 의해 런타임에 생성됩니다. 반면에 파이프라인 변수는 파이프라인 실행을 시작하기 전에 사용자가 제공합니다.
2. **릴리스 오케스트레이션 제어**: CodePipeline은 사용자에게 릴리스 오케스트레이션 작업을 허용합니다. 이러한 작업에는 파이프라인 실행을 재시도, 중지, 차단 및 롤백하는 것이 포함됩니다.
3. **릴리스 안전성**: CodePipeline은 사용자가 릴리스 작업을 자동화할 수 있도록 하여 배포에 릴리스 안전성을 추가합니다. 사용자는 스테이지에 조건을 추가하여 이를 달성할 수 있습니다.

   i. **Entry Gates**: 사용자는 진입 기준(스테이지 조건)을 추가하여 진입 기준이 충족되면 배포를 차단/건너뛸 수 있습니다. EKS action 스테이지에 시간 창을 추가하여 하루/주의 특정 시간 동안 배포 시간을 정할 수 있습니다. 마찬가지로 배포 환경이 정상일 때만 배포를 허용하도록 CloudWatch 알람을 추가할 수 있습니다. 또한 변경 세트가 특정 환경을 대상으로 하는 경우와 같이 특정 조건이 충족되면 배포를 건너뛸 수 있습니다. [릴리스 안전성 블로그](https://aws.amazon.com/blogs/devops/enhance-release-control-with-aws-codepipeline-stage-level-conditions/)

   ii. **Exit gates**: 사용자는 종료 기준(스테이지 조건)을 추가하여 기준이 충족되면 배포를 실패, 재시도 또는 롤백할 수 있습니다. CloudWatch 알람을 추가하고 CloudWatch 알람이 빨간색이면 배포를 롤백할 수 있습니다. 배포 환경이 불안정한 경우 자동 재시도할 수 있습니다. [자동 롤백 블로그](https://aws.amazon.com/blogs/devops/de-risk-releases-with-aws-codepipeline-rollbacks/)

4. **수동 승인** 파이프라인 실행의 오케스트레이션을 자동화하는 것 외에도 CodePipeline을 사용하면 승인 기반 릴리스 프로세스를 구성할 수 있습니다. 수동 승인 action을 통해 애플리케이션 변경 사항을 검사하고 승인/거부할 수 있습니다.

