---
title: "애플리케이션 배포"
sidebar_position: 30
tmdTranslationSourceHash: '48138a90920964475bfb4a0cd93f4fc2'
---

애플리케이션을 배포하기 전에 기존 UI 컴포넌트를 삭제하고 네임스페이스를 다시 생성해 보겠습니다:

```bash
$ kubectl delete namespace ui
$ kubectl create namespace ui
```

이제 파이프라인을 실행해 보겠습니다. 이 파이프라인은 이미지를 빌드하고 EKS 클러스터에 배포할 것입니다.

```bash wait=20
$ git -C ~/environment/codepipeline add .
$ git -C ~/environment/codepipeline commit -am "Initial setup"
$ git -C ~/environment/codepipeline push --set-upstream origin main
```

CodePipeline이 이미지를 빌드하고 EKS 클러스터에 모든 변경 사항을 배포하는 데 3-5분이 소요됩니다. AWS 콘솔에서 파이프라인 진행 상황을 확인하거나 다음 명령어를 사용하여 완료될 때까지 기다릴 수 있습니다:

```bash timeout=900
$ while [[ "$(aws codepipeline list-pipeline-executions --pipeline-name ${EKS_CLUSTER_NAME}-retail-store-cd --query 'pipelineExecutionSummaries[0].trigger.triggerType' --output text)" != "CloudWatchEvent" ]]; do echo "Waiting for pipeline to start ..."; sleep 10; done && echo "Pipeline started."
$ while [[ "$(aws codepipeline list-pipeline-executions --pipeline-name ${EKS_CLUSTER_NAME}-retail-store-cd --query 'pipelineExecutionSummaries[0].status' --output text)" != "Succeeded" ]]; do echo "Waiting for pipeline execution to finish ..."; sleep 10; done && echo "Pipeline execution successful."
```

완료되면 파이프라인은 모든 스테이지가 성공했음을 표시합니다.

![Pipeline complete](/docs/automation/continuousdelivery/codepipeline/pipeline-complete.webp)

이제 파이프라인에 의해 수행된 변경 사항을 검토할 수 있습니다. 먼저 ECR 리포지토리를 확인할 수 있습니다:

<ConsoleButton
  url="https://console.aws.amazon.com/ecr/private-registry/repositories"
  service="ecr"
  label="ECR 콘솔 열기"
/>

`retail-store-sample-ui` 리포지토리를 열고 푸시된 이미지를 확인합니다.

![Image 1](/docs/automation/continuousdelivery/codepipeline/ecr_image.webp)

클러스터에 Helm 릴리스가 설치되었는지도 확인할 수 있습니다:

```bash hook=deployment
$ helm ls -n ui
NAME    NAMESPACE       REVISION        UPDATED                                 STATUS          CHART                                   APP VERSION
ui      ui              1               2025-07-01 05:16:56.016555446 +0000 UTC deployed        retail-store-sample-ui-chart-0.8.5
```

구성에 사용된 값을 확인하여 사용자 정의 이미지 리포지토리와 태그가 사용되었는지 확인합니다:

```bash
$ helm get values -n ui ui
USER-SUPPLIED VALUES:
image:
  repository: 1234567890.dkr.ecr.us-west-2.amazonaws.com/retail-store-sample-ui-sm7zww
  tag: e37f1e7932270d24d7bd7583d484dc2a
```

이는 Deployment를 생성합니다:

```bash
$ kubectl get deployment -n ui
NAME   READY   UP-TO-DATE   AVAILABLE   AGE
ui     1/1     1            1           42s
```

Pod는 파이프라인에서 빌드된 이미지를 사용할 것입니다:

```bash
$ kubectl get deployment -n ui ui -o json | jq -r '.spec.template.spec.containers[0].image'
1234567890.dkr.ecr.us-west-2.amazonaws.com/retail-store-sample-ui-sm7zww:e37f1e7932270d24d7bd7583d484dc2a
```

또한 `deploy_eks` 액션을 클릭하여 로그와 같은 자세한 정보를 볼 수 있습니다:

![Pipeline deploy detail](/docs/automation/continuousdelivery/codepipeline/pipeline-deploy-detail.webp)

이로써 애플리케이션 컨테이너 이미지를 빌드하고 Helm 차트를 사용하여 EKS 클러스터에 배포하는 파이프라인을 성공적으로 생성했습니다.

