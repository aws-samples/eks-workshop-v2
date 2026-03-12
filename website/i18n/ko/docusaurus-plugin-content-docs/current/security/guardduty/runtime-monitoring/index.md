---
title: "EKS Runtime Monitoring"
sidebar_position: 530
tmdTranslationSourceHash: '2591296ddd62b07b47822d55284b43ee'
---

EKS Runtime Monitoring은 Amazon EKS 노드와 컨테이너에 대한 런타임 위협 탐지 범위를 제공합니다. GuardDuty 보안 에이전트(EKS add-on)를 사용하여 개별 EKS 워크로드에 대한 런타임 가시성을 추가합니다. 예를 들어, 파일 액세스, 프로세스 실행, 권한 상승, 네트워크 연결 등을 모니터링하여 잠재적으로 손상될 수 있는 특정 컨테이너를 식별합니다.

EKS Runtime Monitoring을 활성화하면 GuardDuty가 EKS 클러스터 내에서 런타임 이벤트 모니터링을 시작할 수 있습니다. EKS 클러스터에 GuardDuty를 통해 자동으로 또는 수동으로 배포된 보안 에이전트가 없는 경우, GuardDuty는 EKS 클러스터의 런타임 이벤트를 수신할 수 없습니다. 이는 에이전트가 EKS 클러스터 내의 EKS 노드에 배포되어야 함을 의미합니다. GuardDuty가 보안 에이전트를 자동으로 관리하도록 선택하거나, 보안 에이전트 배포 및 업데이트를 수동으로 관리할 수 있습니다.

이 실습에서는 Amazon EKS 클러스터에서 아래 나열된 몇 가지 EKS 런타임 탐지 결과를 생성할 것입니다.

- `Execution:Runtime/NewBinaryExecuted`
- `CryptoCurrency:Runtime/BitcoinTool.B!DNS`
- `Execution:Runtime/NewLibraryLoaded`
- `DefenseEvasion:Runtime/FilelessExecution`

