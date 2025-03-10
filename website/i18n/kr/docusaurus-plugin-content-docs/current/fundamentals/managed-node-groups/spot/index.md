---
title: 스팟 인스턴스
sidebar_position: 50
sidebar_custom_props: { "module": true }
description: "Take advantage of discounts with Amazon EC2 Spot instances on Amazon Elastic Kubernetes Service(EKS)."
---
::required-time

:::tip 시작하기 전에
이 섹션을 위해 환경을 준비하세요.

```bash
$ prepare-environment fundamentals/mng/spot
```

:::

우리의 모든 기존 컴퓨팅 노드는 온디맨드 용량을 사용하고 있습니다. 그러나 EC2 고객이 EKS 워크로드를 실행하기 위해 사용할 수 있는 여러 "[구매 옵션](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/instance-purchasing-options.html)"이 있습니다.

스팟 인스턴스는 온디맨드 가격보다 낮은 가격으로 사용 가능한 여분의 EC2 용량을 사용합니다. 스팟 인스턴스를 사용하면 미사용 EC2 인스턴스를 큰 할인으로 요청할 수 있어 Amazon EC2 비용을 크게 절감할 수 있습니다. 스팟 인스턴스의 시간당 가격을 스팟 가격이라고 합니다. 각 가용 영역의 각 인스턴스 유형에 대한 스팟 가격은 Amazon EC2에 의해 설정되며, 스팟 인스턴스에 대한 장기적인 공급과 수요에 따라 점진적으로 조정됩니다. 용량이 가용할 때마다 스팟 인스턴스가 실행됩니다.

스팟 인스턴스는 무상태, 내결함성, 유연한 애플리케이션에 적합합니다. 여기에는 배치 및 기계 학습 훈련 워크로드, Apache Spark와 같은 빅 데이터 ETL, 큐 처리 애플리케이션 및 무상태 API 엔드포인트가 포함됩니다. 스팟은 시간이 지남에 따라 변할 수 있는 여분의 Amazon EC2 용량이기 때문에, 중단 허용 워크로드에 스팟 용량을 사용하는 것이 좋습니다. 더 구체적으로, 스팟 용량은 필요한 용량을 사용할 수 없는 기간을 견딜 수 있는 워크로드에 적합합니다.

이 실습에서는 EKS 관리형 노드 그룹과 함께 EC2 스팟 용량을 활용하는 방법을 살펴보겠습니다.
