---
title: "CloudWatch에서 확인하기"
sidebar_position: 30
tmdTranslationSourceHash: '4dbd2fb1e2dae8c3a7e9056378720d42'
---

CloudWatch Logs 콘솔에서 로그를 살펴보겠습니다:

<ConsoleButton url="https://console.aws.amazon.com/cloudwatch/home?#logsV2:log-groups" service="cloudwatch" label="CloudWatch 콘솔 열기"/>

**/aws/eks** 접두사로 필터링하고 로그를 확인하려는 클러스터를 선택합니다:

![클러스터 로그 그룹](/docs/observability/logging/cluster-logging/logging-cluster-cw-loggroup.webp)

그룹 내의 여러 로그 스트림이 표시됩니다:

![로그 스트림](/docs/observability/logging/cluster-logging/logging-cluster-cw-logstream.webp)

이러한 로그 스트림 중 하나를 선택하여 EKS control plane이 CloudWatch Logs로 전송하는 항목을 확인할 수 있습니다.

