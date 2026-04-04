---
title: Kubernetes의 마이크로서비스
sidebar_position: 30
tmdTranslationSourceHash: 7cb57f0a8278d341fc9778a2601f0e00
---

이제 샘플 애플리케이션의 전체 아키텍처에 익숙해졌으니, 이를 EKS에 어떻게 초기 배포할지 살펴보겠습니다. **catalog** 컴포넌트를 살펴보며 Kubernetes의 몇 가지 기본 구성 요소를 탐색해 보겠습니다:

![Catalog microservice in Kubernetes](/docs/introduction/getting-started/catalog-microservice.webp)

이 다이어그램에서 고려해야 할 몇 가지 사항이 있습니다:

- catalog API를 제공하는 애플리케이션은 [Pod](https://kubernetes.io/docs/concepts/workloads/pods/)로 실행되며, 이는 Kubernetes에서 배포 가능한 가장 작은 단위입니다. 애플리케이션 Pod는 이전 섹션에서 설명한 컨테이너 이미지를 실행합니다.
- catalog 컴포넌트를 위해 실행되는 Pod는 [Deployment](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)에 의해 생성되며, 이는 catalog Pod의 하나 이상의 "복제본"을 관리하여 수평적으로 확장할 수 있도록 합니다.
- [Service](https://kubernetes.io/docs/concepts/services-networking/service/)는 Pod 집합으로 실행되는 애플리케이션을 노출하는 추상적인 방법이며, 이를 통해 Kubernetes 클러스터 내의 다른 컴포넌트가 catalog API를 호출할 수 있습니다. 각 Service는 자체 DNS 항목을 받습니다.
- MySQL 데이터베이스는 Kubernetes 클러스터 내에서 [StatefulSet](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/)으로 실행되며, 이는 상태 저장 워크로드를 관리하도록 설계되었습니다.
- 이러한 모든 Kubernetes 구성 요소는 전용 catalog Namespace에 그룹화됩니다. 각 애플리케이션 컴포넌트는 자체 Namespace를 가집니다.

마이크로서비스 아키텍처의 각 컴포넌트는 catalog와 개념적으로 유사하며, Deployment를 사용하여 애플리케이션 워크로드 Pod를 관리하고 Service를 사용하여 해당 Pod로 트래픽을 라우팅합니다. 아키텍처에 대한 관점을 확장하면 전체 시스템에서 트래픽이 어떻게 라우팅되는지 고려할 수 있습니다:

![Microservices in Kubernetes](/docs/introduction/getting-started/microservices.webp)

**ui** 컴포넌트는 예를 들어 사용자의 브라우저로부터 HTTP 요청을 받습니다. 그런 다음 아키텍처의 다른 API 컴포넌트에 HTTP 요청을 보내 해당 요청을 처리하고 사용자에게 응답을 반환합니다. 각 다운스트림 컴포넌트는 자체 데이터 저장소 또는 기타 인프라를 가질 수 있습니다. Namespace는 각 마이크로서비스의 리소스를 논리적으로 그룹화하며 소프트 격리 경계 역할도 하여 Kubernetes RBAC 및 Network Policy를 사용하여 효과적으로 제어를 구현하는 데 사용할 수 있습니다.

