---
title: "실제 구현"
sidebar_position: 50
tmdTranslationSourceHash: 7bbd38ed333286f2e174fc5ca7084fd2
---

이전 섹션에서 Amazon EKS를 사용하여 AWS Inferentia용 모델을 훈련하고 Inferentia 노드를 사용하여 EKS에 모델을 배포하는 방법을 살펴보았습니다. 두 예제 모두에서 명령줄에서 컨테이너 내부의 Python 코드를 실행했습니다. 실제 시나리오에서는 이러한 명령을 수동으로 실행하는 것이 아니라 컨테이너가 명령을 실행하도록 해야 합니다.

모델 훈련의 경우 DLC 컨테이너를 베이스 이미지로 사용하고 Python 코드를 추가하려고 할 것입니다. 그런 다음 이 컨테이너 이미지를 Amazon ECR과 같은 컨테이너 리포지토리에 저장합니다. Kubernetes Job을 사용하여 이 컨테이너 이미지를 EKS에서 실행하고 생성된 모델을 S3에 저장합니다.

![Build Model](/docs/aiml/inferentia/CreateModel.webp)

모델에 대한 추론을 실행하려면 다른 애플리케이션이나 사용자가 모델에서 분류 결과를 검색할 수 있도록 코드를 수정해야 합니다. 이는 호출할 수 있고 분류 결과로 응답하는 REST API를 만들어 수행할 수 있습니다. AWS Inferentia 리소스 요구 사항(`aws.amazon.com/neuron`)을 사용하여 클러스터 내에서 이 애플리케이션을 Kubernetes Deployment로 실행합니다.

![Inference Model](/docs/aiml/inferentia/Inference.webp)

