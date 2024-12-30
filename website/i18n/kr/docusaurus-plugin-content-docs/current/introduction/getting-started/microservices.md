---
title: 쿠버네티스의 마이크로서비스
sidebar_position: 30
---

이제 샘플 애플리케이션의 전체 아키텍처에 대해 알게 되었으니, 이를 EKS에 어떻게 초기 배포할까요? `catalog` 컴포넌트를 살펴보면서 Kubernetes의 기본 구성 요소들을 알아보겠습니다:

![Catalog microservice in Kubernetes](./assets/catalog-microservice.webp)

이 다이어그램에서 고려해야 할 사항들이 있습니다:

- Catalog API를 제공하는 애플리케이션은 [Pod](https://kubernetes.io/docs/concepts/workloads/pods/)로 실행되며, Pod는 Kubernetes에서 가장 작은 배포 단위입니다. 애플리케이션 Pod는 이전 섹션에서 설명한 컨테이너 이미지를 실행합니다.
- catalog 컴포넌트를 위한 Pod는 [Deployment](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)에 의해 생성되며, 수평적 확장이 가능하도록 catalog Pod의 하나 이상의 "복제본"을 관리할 수 있습니다.
- [Service](https://kubernetes.io/docs/concepts/services-networking/service/)는 Pod 집합으로 실행되는 애플리케이션을 노출하는 추상적인 방법이며, 이를 통해 Kubernetes 클러스터 내의 다른 컴포넌트들이 catalog API를 호출할 수 있습니다. 각 Service는 고유한 DNS 항목을 가집니다.
- 이 워크샵은 상태 저장 워크로드를 관리하도록 설계된 [StatefulSet](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/)으로 Kubernetes 클러스터 내에서 실행되는 MySQL 데이터베이스로 시작합니다.
- 이러한 모든 Kubernetes 구성요소들은 전용 catalog Namespace에 그룹화됩니다. 각 애플리케이션 컴포넌트는 자체 Namespace를 가집니다.

마이크로서비스 아키텍처의 각 컴포넌트는 개념적으로 catalog와 유사하며, Deployment를 사용하여 애플리케이션 워크로드 Pod를 관리하고 Service를 사용하여 해당 Pod로 트래픽을 라우팅합니다. 아키텍처를 더 넓게 살펴보면 전체 시스템에서 트래픽이 어떻게 라우팅되는지 알 수 있습니다:

![Microservices in Kubernetes](./assets/microservices.webp)

The **ui** component receives HTTP requests from, for example, a user's browser. It then makes HTTP requests to other API components in the architecture to fulfill that request and returns a response to the user. Each of the downstream components may have their own data stores or other infrastructure. The Namespaces are a logical grouping of the resources for each microservice and also act as a soft isolation boundary, which can be used to effectively implement controls using Kubernetes RBAC and Network Policies.