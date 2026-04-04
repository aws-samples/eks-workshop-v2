---
title: "Git 리포지토리"
sidebar_position: 10
tmdTranslationSourceHash: 'c62b494fcd4d8e73bd06482e73ffc5cd'
---

:::note
CodePipeline은 AWS CodeConnections를 통해 GitHub, GitLab, Bitbucket을 Git 기반 소스로 지원합니다. 실제 애플리케이션에서는 이러한 소스를 사용해야 합니다. 하지만 이 실습에서는 간단하게 S3를 소스 리포지토리로 사용하겠습니다.
:::

이 모듈은 S3를 소스 액션으로 사용하며, 웹 IDE에서 `git`을 통해 해당 버킷을 채우기 위해 [git-remote-s3](https://github.com/awslabs/git-remote-s3?tab=readme-ov-file#repo-as-s3-source-for-aws-codepipeline) 라이브러리를 사용합니다.

리포지토리는 다음으로 구성됩니다:

1. 사용자 정의 UI 컨테이너 이미지를 생성하기 위한 Dockerfile
2. 컴포넌트를 배포하기 위한 Helm 차트
3. 배포되는 이미지를 재정의하기 위한 `values.yaml` 파일

```text
.
├── chart/
|   ├── templates/
|   ├── Chart.yaml
│   └── values.yaml
|── values.yaml
└── Dockerfile
```

사용할 Dockerfile은 이 실습을 위해 의도적으로 단순화되었습니다:

```file
manifests/modules/automation/continuousdelivery/codepipeline/repo/Dockerfile
```

리포지토리 루트의 `values.yaml` 파일은 올바른 컨테이너 이미지와 태그를 구성하는 역할만 담당합니다:

::yaml{file="manifests/modules/automation/continuousdelivery/codepipeline/repo/values.yaml"}

`IMAGE_URL`과 `IMAGE_REPOSITORY` 환경 변수는 나중에 보겠지만 파이프라인에서 설정됩니다.

먼저 Git을 설정하겠습니다:

```bash
$ git config --global user.email "you@eksworkshop.com"
$ git config --global user.name "Your Name"
```

그런 다음 Git 리포지토리로 사용할 디렉터리에 다양한 파일을 복사합니다:

```bash timeout=120
$ mkdir -p ~/environment/codepipeline/chart
$ git -C ~/environment/codepipeline init -b main
$ git -C ~/environment/codepipeline remote add \
  origin s3+zip://${EKS_CLUSTER_NAME}-${AWS_ACCOUNT_ID}-retail-store-sample-ui/my-repo
$ cp -R ~/environment/eks-workshop/modules/automation/continuousdelivery/codepipeline/repo/* \
  ~/environment/codepipeline
$ helm pull oci://public.ecr.aws/aws-containers/retail-store-sample-ui-chart:1.2.1 \
  -d /tmp
$ tar zxf /tmp/retail-store-sample-ui-chart-1.2.1.tgz \
  -C ~/environment/codepipeline/chart --strip-components=1
```

