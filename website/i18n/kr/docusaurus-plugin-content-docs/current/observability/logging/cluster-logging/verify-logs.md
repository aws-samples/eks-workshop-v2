---
title: "CloudWatch에서 보기"
sidebar_position: 30
---

CloudWatch Logs 콘솔에서 로그를 살펴보겠습니다:

<ConsoleButton url="https://console.aws.amazon.com/cloudwatch/home?#logsV2:log-groups" service="cloudwatch" label="Open CloudWatch console"/>

**/aws/eks** 접두사로 필터링하고 로그를 확인하려는 클러스터를 선택하세요:

![클러스터 로그 그룹](./assets/logging-cluster-cw-loggroup.webp)

그룹 내에 여러 로그 스트림이 표시됩니다:

![로그 스트림](./assets/logging-cluster-cw-logstream.webp)

이러한 로그 스트림 중 하나를 선택하여 EKS 컨트롤 플레인에서 CloudWatch Logs로 전송되는 항목들을 확인할 수 있습니다.