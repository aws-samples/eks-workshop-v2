---
title: "Control Plane"
sidebar_position: 3
weight: 30
tmdTranslationSourceHash: '43a721c193e756f71a320dccfdefc13b'
---

Control Plane 프레임워크를 사용하면 표준 Kubernetes CLI인 `kubectl`을 사용하여 Kubernetes에서 직접 AWS 리소스를 관리할 수 있습니다. AWS 관리형 서비스를 Kubernetes의 [Custom Resource Definitions (CRDs)](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/)로 모델링하고 이러한 정의를 클러스터에 적용하여 이를 수행합니다. 이는 개발자가 컨테이너에서 AWS 관리형 서비스에 이르기까지 전체 애플리케이션 아키텍처를 모델링하고 단일 YAML 매니페스트로 백업할 수 있음을 의미합니다. Control Plane은 새로운 애플리케이션을 생성하는 데 걸리는 시간을 줄이고 클라우드 네이티브 솔루션을 원하는 상태로 유지하는 데 도움이 될 것으로 예상됩니다.

Control Plane을 위한 두 가지 인기 있는 오픈 소스 프로젝트는 [AWS Controllers for Kubernetes (ACK)](https://aws-controllers-k8s.github.io/community/)와 CNCF 인큐베이팅 프로젝트인 [Crossplane](https://www.crossplane.io/)이며, 둘 다 AWS 서비스를 지원합니다. 이 워크샵 모듈은 이 두 프로젝트에 중점을 둡니다.

