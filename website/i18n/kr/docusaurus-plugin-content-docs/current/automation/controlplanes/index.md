---
title: "컨트롤 플레인"
sidebar_position: 3
weight: 30
---

컨트롤 플레인 프레임워크를 사용하면 표준 Kubernetes CLI인 `kubectl`을 사용하여 Kubernetes에서 직접 AWS 리소스를 관리할 수 있습니다. 이는 AWS 관리형 서비스를 Kubernetes의 [커스텀 리소스 정의(CRDs)](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/)로 모델링하고 이러한 정의를 클러스터에 적용함으로써 가능합니다. 이는 개발자가 단일 YAML 매니페스트에서 컨테이너부터 AWS 관리형 서비스까지 전체 애플리케이션 아키텍처를 모델링할 수 있다는 것을 의미합니다. 컨트롤 플레인은 새로운 애플리케이션을 만드는 데 걸리는 시간을 줄이고, 클라우드 네이티브 솔루션을 원하는 상태로 유지하는 데 도움이 될 것으로 예상됩니다.

컨트롤 플레인을 위한 두 가지 인기 있는 오픈소스 프로젝트는 [AWS Controllers for Kubernetes (ACK)](https://aws-controllers-k8s.github.io/community/)와 CNCF 인큐베이팅 프로젝트인 [Crossplane](https://www.crossplane.io/)입니다. 두 프로젝트 모두 AWS 서비스를 지원합니다. 이 워크샵 모듈은 이 두 프로젝트에 초점을 맞추고 있습니다.