---
title: "AWS Controllers for Kubernetes (ACK)"
sidebar_position: 1
sidebar_custom_props: { "module": true }
description: "AWS Controllers for Kubernetes를 사용하여 Amazon Elastic Kubernetes Service에서 AWS 서비스를 직접 관리합니다."
tmdTranslationSourceHash: "631c04d31582052f4c23f1864087ceda"
---

::required-time

:::tip 시작하기 전에
이 섹션을 위한 환경을 준비합니다:

```bash timeout=300 wait=30
$ prepare-environment automation/controlplanes/ack
```

이 명령은 실습 환경에 다음과 같은 변경 사항을 적용합니다:

- Amazon EKS 클러스터에 DynamoDB용 AWS Controllers 설치

이러한 변경 사항을 적용하는 Terraform은 [여기](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/automation/controlplanes/ack/.workshop/terraform)에서 확인할 수 있습니다.

:::

[AWS Controllers for Kubernetes (ACK)](https://aws-controllers-k8s.github.io/community/) 프로젝트를 사용하면 익숙한 YAML 구문을 사용하여 Kubernetes에서 직접 AWS 서비스 리소스를 정의하고 사용할 수 있습니다.

ACK를 사용하면 Kubernetes 애플리케이션을 위해 데이터베이스([RDS](https://aws-controllers-k8s.github.io/community/docs/tutorials/rds-example/) 등) 및 큐([SQS](https://aws-controllers-k8s.github.io/community/docs/tutorials/sqs-example/) 등)와 같은 AWS 서비스를 클러스터 외부에서 수동으로 리소스를 정의하지 않고도 활용할 수 있습니다. 이를 통해 애플리케이션 종속성 관리의 전체적인 복잡성을 줄일 수 있습니다.

샘플 애플리케이션은 데이터베이스 및 메시지 큐와 같은 stateful 워크로드를 포함하여 클러스터 내에서 완전히 실행할 수 있지만(개발에 적합), 테스트 및 프로덕션 환경에서 Amazon DynamoDB 및 Amazon MQ와 같은 AWS 관리형 서비스를 사용하면 팀이 데이터베이스나 메시지 브로커를 관리하는 대신 고객과 비즈니스 프로젝트에 집중할 수 있습니다.

이 실습에서는 ACK를 사용하여 이러한 서비스를 프로비저닝하고 애플리케이션을 이러한 AWS 관리형 서비스에 연결하기 위한 바인딩 정보가 포함된 secrets 및 configmaps를 생성합니다.

학습 목적으로 helm을 사용하여 ACK 컨트롤러를 설치합니다. 또 다른 옵션은 클러스터에 AWS Service Controllers를 신속하게 배포할 수 있는 Terraform을 사용하는 것입니다. 자세한 내용은 [ACK Terraform 모듈 문서](https://registry.terraform.io/modules/aws-ia/eks-ack-addons/aws/latest#module_dynamodb)를 참조하세요.

![EKS with DynamoDB](/docs/automation/controlplanes/ack/eks-workshop-ddb.webp)

