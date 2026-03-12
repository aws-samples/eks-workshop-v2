---
title: Mountpoint for Amazon S3
sidebar_position: 30
sidebar_custom_props: { "module": true }
description: "Amazon Elastic Kubernetes Service에서 Amazon S3를 사용한 워크로드를 위한 서버리스 객체 스토리지."
tmdTranslationSourceHash: '1f3a8f50d3c93f1191e94ec6e7a85a61'
---

::required-time

:::tip 시작하기 전에
이 섹션을 위한 환경을 준비합니다:

```bash timeout=1800 wait=30
$ prepare-environment fundamentals/storage/s3
```

이 명령은 실습 환경에 다음과 같은 변경사항을 적용합니다:

- Mountpoint for Amazon S3 CSI 드라이버를 위한 IAM 역할 생성
- 워크샵에서 사용할 Amazon S3 버킷 생성

이러한 변경사항을 적용하는 Terraform 코드는 [여기](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/fundamentals/storage/s3/.workshop/terraform)에서 확인할 수 있습니다.

:::

[Amazon Simple Storage Service](https://docs.aws.amazon.com/AmazonS3/latest/userguide/Welcome.html) (Amazon S3)는 업계 최고 수준의 확장성, 데이터 가용성, 보안 및 성능을 제공하는 객체 스토리지 서비스입니다. 모든 규모와 업종의 조직에서 Amazon S3를 사용하여 데이터 레이크, 웹사이트, 모바일 애플리케이션, 백업 및 복원, 엔터프라이즈 애플리케이션, IoT 디바이스, 빅데이터 분석 등 다양한 사용 사례에 필요한 모든 양의 데이터를 저장하고 보호합니다. Amazon S3는 특정 비즈니스, 조직 및 규정 준수 요구 사항에 따라 데이터에 대한 액세스를 최적화, 구성 및 구성하기 위한 포괄적인 관리 기능을 제공합니다.

[Mountpoint for Amazon S3](https://github.com/awslabs/mountpoint-s3)는 [Amazon S3 버킷을 로컬 파일 시스템으로 마운트](https://aws.amazon.com/blogs/storage/the-inside-story-on-mountpoint-for-amazon-s3-a-high-performance-open-source-file-client/)할 수 있는 고처리량 파일 클라이언트입니다. Mountpoint for Amazon S3를 사용하면 애플리케이션이 open 및 read와 같은 표준 파일 작업을 통해 Amazon S3에 저장된 객체에 액세스할 수 있습니다. Mountpoint for Amazon S3는 이러한 작업을 S3 객체 API 호출로 투명하게 변환하여 애플리케이션이 익숙한 파일 인터페이스를 통해 Amazon S3의 탄력적인 스토리지 및 처리량에 액세스할 수 있도록 합니다.

이 실습에서는 이미지를 저장할 Amazon S3 버킷을 생성한 다음 Mountpoint for Amazon S3를 사용하여 해당 버킷을 마운트하여 EKS 클러스터에 영구적이고 공유된 스토리지를 제공합니다.

