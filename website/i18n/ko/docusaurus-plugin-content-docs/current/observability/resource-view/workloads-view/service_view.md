---
title: "Services and Endpoints"
sidebar_position: 20
tmdTranslationSourceHash: 'a11c44ee0945ad6873bae46672cfbdb7'
---

Kubernetes 서비스 및 네트워킹 리소스를 보려면 <i>Resources</i> 탭을 클릭하세요. <i>Service and Networking</i> 섹션으로 드릴다운하면 서비스 및 네트워킹의 일부인 여러 Kubernetes API 리소스 타입을 볼 수 있습니다. 이 실습에서는 Pod 집합에서 실행 중인 애플리케이션을 Service, Endpoint 및 Ingress로 노출하는 방법을 자세히 설명합니다.

[Service](https://kubernetes.io/docs/concepts/services-networking/service/) 리소스 뷰는 클러스터에서 Pod 집합에서 실행 중인 애플리케이션을 노출하는 모든 서비스를 표시합니다.

![Insights](/img/resource-view/service-view.jpg)

<i>cart</i> 서비스를 선택하면 Info 섹션에서 selector(서비스의 대상이 되는 Pod 집합은 일반적으로 selector에 의해 결정됩니다), 실행 중인 프로토콜 및 포트, 그리고 모든 레이블과 어노테이션을 포함한 서비스에 대한 세부 정보가 표시됩니다.
Pod는 서비스에 대한 엔드포인트를 통해 자신을 노출합니다. 엔드포인트는 Pod의 IP 주소와 포트가 동적으로 할당되는 리소스입니다. 엔드포인트는 Kubernetes 서비스에 의해 참조됩니다.

![Insights](/img/resource-view/service-endpoint.png)

이 샘플 애플리케이션의 경우 <i>Endpoints</i>를 클릭하고 엔드포인트와 연결된 IP 주소 및 포트의 세부 정보와 Info, Labels 및 Annotations 섹션을 살펴보세요.

