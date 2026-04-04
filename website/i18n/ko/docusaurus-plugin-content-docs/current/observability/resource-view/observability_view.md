---
title: "Observability"
sidebar_position: 30
tmdTranslationSourceHash: '4864a8b132bce526aab8be8bd4718917'
---

애플리케이션, 네트워크 및 인프라를 주의 깊게 모니터링하는 것은 최적의 성능을 보장하고, 병목 현상을 식별하며, 문제를 신속하게 해결하는 데 매우 중요합니다.
AWS 관측 가능성을 사용하면 네트워크, 인프라 및 애플리케이션의 텔레메트리를 수집, 상관 관계 분석, 집계 및 분석하여 시스템의 동작, 성능 및 상태에 대한 인사이트를 얻을 수 있습니다. 이러한 인사이트는 문제를 더 빠르게 감지, 조사 및 해결하는 데 도움이 됩니다.

EKS 콘솔의 Observability 탭은 EKS 클러스터에 대한 엔드 투 엔드 관측 가능성에 대한 포괄적인 뷰를 제공합니다. 아래와 같이 Prometheus 메트릭 또는 CloudWatch 메트릭을 사용하여 클러스터, 인프라 및 애플리케이션 메트릭을 수집하고 [Amazon Managed Service for Prometheus](https://aws.amazon.com/prometheus/)로 전송할 수 있습니다. [Amazon Managed Grafana](https://aws.amazon.com/grafana/)를 사용하여 대시보드에서 메트릭을 시각화하고 알림을 생성할 수 있습니다.

Prometheus는 스크래핑(scraping)이라는 풀 기반 모델을 통해 클러스터에서 메트릭을 검색하고 수집합니다. 스크래퍼는 클러스터 인프라와 컨테이너화된 애플리케이션에서 데이터를 수집하도록 설정됩니다. **Add scraper**를 사용하여 클러스터에 대한 스크래퍼를 설정하세요.

CloudWatch Observability add-on을 통해 클러스터에서 CloudWatch Observability를 활성화할 수 있습니다. add-ons 탭으로 이동하여 CloudWatch Observability add-on을 설치하면 CloudWatch Application Signals와 Container Insights가 활성화되고 CloudWatch로 텔레메트리 수집이 시작됩니다.

![Insights](/img/resource-view/observability-view.jpg)

