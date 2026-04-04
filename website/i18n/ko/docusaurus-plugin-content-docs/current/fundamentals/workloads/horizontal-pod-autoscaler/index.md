---
title: "Horizontal Pod Autoscaler"
sidebar_position: 10
sidebar_custom_props: { "module": true }
description: "Horizontal Pod Autoscaler를 사용하여 Amazon Elastic Kubernetes Service의 워크로드를 자동으로 스케일링합니다."
tmdTranslationSourceHash: 'fa2252b7e780d07180e66fb2144b655c'
---

::required-time

이 실습에서는 Horizontal Pod Autoscaler(HPA)를 사용하여 Deployment 또는 ReplicaSet의 Pod를 스케일링하는 방법을 살펴봅니다. HPA는 Kubernetes API 리소스 및 컨트롤러로 구현됩니다. 리소스는 컨트롤러의 동작을 결정합니다. Controller Manager는 각 HorizontalPodAutoscaler 정의에 지정된 메트릭에 대해 리소스 사용률을 쿼리합니다. 컨트롤러는 평균 CPU 사용률, 평균 메모리 사용률 또는 기타 커스텀 메트릭과 같은 메트릭을 관찰하여 Replication Controller 또는 Deployment의 레플리카 수를 사용자가 지정한 목표에 맞게 주기적으로 조정합니다. 메트릭은 리소스 메트릭 API(Pod별 리소스 메트릭용) 또는 커스텀 메트릭 API(기타 모든 메트릭용)에서 가져옵니다.

Kubernetes Metrics Server는 클러스터의 리소스 사용 데이터를 확장 가능하고 효율적으로 집계하는 도구입니다. Horizontal Pod Autoscaler에 필요한 컨테이너 메트릭을 제공합니다. Metrics Server는 Amazon EKS 클러스터에 기본적으로 배포되지 않습니다.

<img src={require('@site/static/docs/fundamentals/workloads/horizontal-pod-autoscaler/hpa.webp').default}/>

