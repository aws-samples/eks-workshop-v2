---
title: "파이프라인 설정"
sidebar_position: 20
tmdTranslationSourceHash: 'dae07d466d20246cd56915cb867dd8af'
---

파이프라인을 실행하기 전에 CodePipeline이 클러스터에 배포할 수 있도록 클러스터를 구성해 보겠습니다. CodePipeline은 클러스터에서 작업(`kubectl` 또는 `helm`)을 수행할 권한이 필요합니다. 이 작업이 성공하려면 codepipeline 파이프라인 서비스 역할을 클러스터에 액세스 항목으로 추가해야 합니다:

```bash
$ aws eks create-access-entry --cluster-name ${EKS_CLUSTER_NAME} \
  --principal-arn "arn:aws:iam::${AWS_ACCOUNT_ID}:role/${EKS_CLUSTER_NAME}-codepipeline-role" \
  --type STANDARD
$ aws eks associate-access-policy --cluster-name ${EKS_CLUSTER_NAME} \
  --principal-arn "arn:aws:iam::${AWS_ACCOUNT_ID}:role/${EKS_CLUSTER_NAME}-codepipeline-role" \
  --policy-arn "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy" \
  --access-scope '{"type":"cluster"}'
```

설정된 CodePipeline을 살펴보고, 생성에 사용된 CloudFormation을 참조해 보겠습니다.

![Pipeline overview](/docs/automation/continuousdelivery/codepipeline/pipeline.webp)

아래 버튼을 사용하여 콘솔에서 파이프라인으로 이동할 수 있습니다:

<ConsoleButton
  url="https://console.aws.amazon.com/codesuite/codepipeline/pipelines/eks-workshop-retail-store-cd/view"
  service="codepipeline"
  label="Open CodePipeline console"
/>

### Source

::yaml{file="manifests/modules/automation/continuousdelivery/codepipeline/.workshop/terraform/pipeline.yaml" zoomPath="Resources.CodePipeline.Properties.Stages.0"}

앞서 언급했듯이 이 파이프라인은 S3 버킷에서 애플리케이션 소스 코드를 가져오도록 구성되어 있습니다. 여기서는 S3 버킷 이름과 소스 파일 아카이브가 저장된 키와 같은 정보를 제공합니다.

### Build

::yaml{file="manifests/modules/automation/continuousdelivery/codepipeline/.workshop/terraform/pipeline.yaml" zoomPath="Resources.CodePipeline.Properties.Stages.1"}

이 단계는 [ECRBuildAndPublish 작업](https://docs.aws.amazon.com/codepipeline/latest/userguide/action-reference-ECRBuildAndPublish.html)을 사용하여 컨테이너 이미지를 빌드하는 역할을 합니다. 소스 리포지토리의 루트에 `Dockerfile`이 있을 것으로 예상하는 기본 위치를 사용한 다음, 구성한 ECR 리포지토리에 푸시합니다. S3 버킷의 소스 코드 리포지토리 아카이브의 [ETag](https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html#ChecksumTypes)를 사용하여 컨테이너 이미지에 태그를 지정합니다. 이는 리포지토리 파일의 해시로, 이 경우 Git 커밋 ID와 유사하게 처리하고 있습니다.

### Deploy

::yaml{file="manifests/modules/automation/continuousdelivery/codepipeline/.workshop/terraform/pipeline.yaml" zoomPath="Resources.CodePipeline.Properties.Stages.2"}

마지막으로 파이프라인은 [EKSDeploy 작업](https://docs.aws.amazon.com/codepipeline/latest/userguide/action-reference-EKS.html)을 사용하여 워크로드를 EKS 클러스터에 배포합니다. 소스 리포지토리의 `chart` 디렉터리에 있는 Helm 차트를 사용하도록 구성했습니다.

주목해야 할 중요한 구성 매개변수는 빌드된 컨테이너 이미지가 사용되도록 `IMAGE_TAG` 값이 제공되는 `EnvironmentVariables` 섹션입니다. "Build" 단계에서와 같이 S3의 리포지토리 코드 아카이브의 ETag 값을 사용하여 빌드된 새 이미지가 사용되도록 하고 있습니다.

