---
title: "워크로드"
sidebar_position: 20
---
이제 컴퓨팅 자동 확장의 개념을 확립했으므로, 클러스터에서 리소스를 확장하고 워크로드를 관리하는 다양한 방법을 종합적으로 살펴볼 수 있습니다. 자동 확장을 위한 세 가지 주요 메커니즘을 다룰 것입니다:

- 수평적 파드 오토스케일러 (HPA - Horizontal Pod Autoscaler)
- 클러스터 비례 오토스케일러 (CPA - Cluster Proportional Autoscaler)
- Kubernetes 이벤트 드리븐 오토스케일러 (KEDA - Kubernetes Event-Driven Autoscaler)

이 장에서는 클러스터의 워크로드를 관리하기 위해 수평적 파드 오토스케일러(HPA), 클러스터 비례 오토스케일러(CPA) 및 Kubernetes 이벤트 드리븐 오토스케일러(KEDA)을 구성하고 사용하는 과정을 살펴보겠습니다.
