---
title: "서비스 및 엔드포인트"
sidebar_position: 20
---

Kubernetes 서비스 및 네트워킹 리소스를 보려면 <i>리소스</i> 탭을 클릭하세요. <i>서비스 및 네트워킹</i> 섹션으로 들어가면 서비스 및 네트워킹의 일부인 여러 Kubernetes API 리소스 유형을 볼 수 있습니다. 이 실습 연습에서는 Pod 세트에서 실행 중인 애플리케이션을 서비스, 엔드포인트 및 인그레스로 노출하는 방법을 자세히 설명합니다.

[서비스](https://kubernetes.io/docs/concepts/services-networking/service/) 리소스 뷰는 클러스터의 Pod 세트에서 실행 중인 애플리케이션을 노출하는 모든 서비스를 표시합니다.

![Insights](/img/resource-view/service-view.jpg)

<i>cart</i> 서비스를 선택하면 표시되는 뷰에는 Info 섹션에 서비스에 대한 세부 정보가 포함됩니다. 여기에는 셀렉터(서비스가 대상으로 하는 Pod 세트는 일반적으로 셀렉터에 의해 결정됨), 실행 중인 프로토콜 및 포트, 그리고 모든 레이블 및 주석이 포함됩니다.
Pod는 엔드포인트를 통해 서비스에 자신을 노출합니다. 엔드포인트는 Pod의 IP 주소와 포트를 동적으로 할당받는 리소스입니다. 엔드포인트는 Kubernetes 서비스에 의해 참조됩니다.

![Insights](/img/resource-view/service-endpoint.png)

이 샘플 애플리케이션의 경우, <i>엔드포인트</i>를 클릭하고 엔드포인트와 연결된 IP 주소 및 포트의 세부 정보와 함께 Info, 레이블 및 주석 섹션을 탐색해보세요.