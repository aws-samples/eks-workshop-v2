---
title: Amazon S3용 마운트포인트
sidebar_position: 30
sidebar_custom_props: { "module": true }
description: "Amazon Elastic Kubernetes Service(EKS)의 워크로드를 위한 Amazon S3의 서버리스 객체 스토리지."
---
::required-time

:::tip 시작하기 전에
이 섹션을 위한 환경을 준비하세요:

```bash
$ prepare-environment fundamentals/storage/s3
```

다음과 같은 변경사항이 실습 환경에 적용됩니다:

* Amazon S3 CSI 드라이버를 위한 Mountpoint용 IAM 역할 생성
* 워크샵에서 사용할 Amazon S3 버킷 생성

[여기](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/fundamentals/storage/s3/.workshop/terraform)에서 이러한 변경사항을 적용하는 Terraform을 확인할 수 있습니다.

:::



[Amazon Simple Storage Service](https://docs.aws.amazon.com/AmazonS3/latest/userguide/Welcome.html) (Amazon S3)는 업계 최고의 확장성, 데이터 가용성, 보안 및 성능을 제공하는 객체 스토리지 서비스입니다. 모든 규모와 산업의 고객들이 데이터 레이크, 웹사이트, 모바일 애플리케이션, 백업 및 복원, 아카이브, 기업용 애플리케이션, IoT 장치, 빅데이터 분석과 같은 다양한 사용 사례에 대해 Amazon S3를 사용하여 데이터를 저장하고 보호할 수 있습니다. Amazon S3는 특정 비즈니스, 조직 및 규정 준수 요구사항을 충족하도록 데이터를 최적화, 구성 및 접근을 구성할 수 있는 관리 기능을 제공합니다.

[`Mountpoint for Amazon S3`](https://github.com/awslabs/mountpoint-s3)는 [Amazon S3 버킷을 로컬 파일 시스템으로 마운트](https://aws.amazon.com/blogs/storage/the-inside-story-on-mountpoint-for-amazon-s3-a-high-performance-open-source-file-client/)하기 위한 간단하고 높은 처리량을 가진 파일 클라이언트입니다. `Mountpoint for Amazon S3`를 사용하면 애플리케이션이 open과 read 같은 파일 작업을 통해 Amazon S3에 저장된 객체에 접근할 수 있습니다. `Mountpoint for Amazon S3`는 이러한 작업을 S3 객체 API 호출로 자동 변환하여, 파일 인터페이스를 통해 애플리케이션이 Amazon S3의 탄력적인 스토리지와 처리량에 접근할 수 있게 합니다.

이 실습에서는 이미지를 저장할 Amazon S3 버킷을 생성한 다음, `Mountpoint for Amazon S3`를 사용하여 해당 S3 버킷을 마운트하여 EKS 클러스터에 영구적이고 공유된 스토리지를 제공할 것입니다. 다음 주제들을 다룰 것입니다:

* 임시 컨테이너 스토리지
* `Mountpoint for Amazon S3` 소개
* `Mountpoint for Amazon S3`를 사용한 영구 객체 스토리지
