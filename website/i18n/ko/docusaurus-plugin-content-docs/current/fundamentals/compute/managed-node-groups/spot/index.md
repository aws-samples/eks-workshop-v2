---
title: Spot 인스턴스
sidebar_position: 30
sidebar_custom_props: { "module": true }
description: "Amazon Elastic Kubernetes Service에서 Amazon EC2 Spot 인스턴스를 활용하여 할인 혜택을 받으세요."
tmdTranslationSourceHash: e90f38c68730f3a44396b0fccc001b71
---

::required-time

:::tip 시작하기 전에
이 섹션을 위한 환경을 준비하세요.

```bash timeout=300 wait=30
$ prepare-environment fundamentals/mng/spot
```

:::

현재 우리의 모든 컴퓨팅 노드는 On-Demand 용량을 사용하고 있습니다. 하지만 EKS 워크로드를 실행하는 EC2 고객이 사용할 수 있는 여러 "[구매 옵션](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/instance-purchasing-options.html)"이 있습니다.

Spot 인스턴스는 On-Demand 가격보다 저렴하게 사용할 수 있는 여유 EC2 용량을 사용합니다. Spot 인스턴스를 사용하면 사용하지 않는 EC2 인스턴스를 대폭 할인된 가격으로 요청할 수 있으므로 Amazon EC2 비용을 크게 절감할 수 있습니다. Spot 인스턴스의 시간당 가격을 Spot 가격이라고 합니다. 각 가용 영역의 각 인스턴스 유형에 대한 Spot 가격은 Amazon EC2에서 설정하며, Spot 인스턴스의 장기적인 공급과 수요를 기반으로 점진적으로 조정됩니다. 용량이 있을 때마다 Spot 인스턴스가 실행됩니다.

Spot 인스턴스는 상태를 유지하지 않고(stateless), 내결함성이 있으며, 유연한 애플리케이션에 적합합니다. 여기에는 배치 및 머신 러닝 훈련 워크로드, Apache Spark와 같은 빅데이터 ETL, 큐 처리 애플리케이션, 상태를 유지하지 않는 API 엔드포인트가 포함됩니다. Spot은 여유 Amazon EC2 용량이며 시간이 지남에 따라 변경될 수 있으므로 중단 허용 가능한 워크로드에 Spot 용량을 사용하는 것이 좋습니다. 보다 구체적으로, Spot 용량은 필요한 용량을 사용할 수 없는 기간을 허용할 수 있는 워크로드에 적합합니다.

이 실습에서는 EKS managed node groups와 함께 EC2 Spot 용량을 활용하는 방법을 살펴보겠습니다.

