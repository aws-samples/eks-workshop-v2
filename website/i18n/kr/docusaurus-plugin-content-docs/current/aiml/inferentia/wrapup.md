---
title: "실제 구현"
sidebar_position: 40
---

이전 섹션에서 우리는 Amazon EKS를 사용하여 AWS Inferentia용 모델을 구축하고 Inferentia 노드를 사용하여 EKS에 모델을 배포하는 방법을 살펴보았습니다. 이 두 예제 모두에서 우리는 명령줄에서 컨테이너 내부의 Python 코드를 실행했습니다. 실제 시나리오에서는 이러한 명령을 수동으로 실행하는 것이 아니라 컨테이너가 명령을 실행하도록 하고자 합니다.

모델 구축을 위해서는 DLC 컨테이너를 기본 이미지로 사용하고 여기에 Python 코드를 추가하고자 합니다. 그런 다음 이 컨테이너 이미지를 Amazon ECR과 같은 컨테이너 저장소에 저장합니다. Kubernetes Job을 사용하여 EKS에서 이 컨테이너 이미지를 실행하고 생성된 모델을 S3에 저장합니다.

![모델 구축](./assets/CreateModel.webp)

모델에 대한 추론을 실행하기 위해서는 다른 애플리케이션이나 사용자가 모델로부터 분류 결과를 검색할 수 있도록 코드를 수정하고자 합니다. 이는 호출할 수 있고 분류 결과로 응답하는 REST API를 생성함으로써 가능합니다. 이 애플리케이션을 AWS Inferentia 리소스 요구사항: `aws.amazon.com/neuron`을 사용하여 클러스터 내에서 Kubernetes Deployment로 실행합니다.

![추론 모델](./assets/Inference.webp)