---
title: "Fluent Bit 사용하기"
sidebar_position: 30
tmdTranslationSourceHash: '97df5abbfec6a9f9822044e8d381f7b2'
---

Pod에서 실행되는 Kubernetes 클러스터 컴포넌트의 경우, 기본 로깅 메커니즘을 우회하여 `/var/log` 디렉터리 내부의 파일에 기록합니다. 각 노드에 DaemonSet으로 Fluent Bit와 같은 노드 레벨 로깅 에이전트를 배포하여 Pod 레벨 로깅을 구현할 수 있습니다.

[Fluent Bit](https://fluentbit.io/)는 다양한 소스에서 데이터와 로그를 수집하고, 필터로 강화한 다음 CloudWatch, Kinesis Data Firehose, Kinesis Data Streams 및 Amazon OpenSearch Service와 같은 여러 대상으로 전송할 수 있는 경량 로그 프로세서 및 포워더입니다.

AWS는 CloudWatch Logs와 Kinesis Data Firehose를 위한 플러그인이 포함된 Fluent Bit 이미지를 제공합니다. [AWS for Fluent Bit](https://github.com/aws/aws-for-fluent-bit) 이미지는 [Amazon ECR Public Gallery](https://gallery.ecr.aws/aws-observability/aws-for-fluent-bit)에서 사용할 수 있습니다.

Fluent Bit는 다양한 대상으로 로그를 전송하는 데 사용할 수 있습니다. 그러나 이 실습에서는 컨테이너 로그를 CloudWatch로 전송하는 데 어떻게 활용되는지 살펴보겠습니다.

![Fluent-bit Architecture](/docs/observability/logging/pod-logging/fluentbit-architecture.webp)

다음 섹션에서는 Fluent Bit 에이전트가 이미 DaemonSet으로 실행되어 컨테이너/Pod 로그를 CloudWatch Logs로 전송하고 있는지 확인하는 방법을 살펴보겠습니다. [컨테이너에서 CloudWatch Logs로 로그를 전송하도록 Fluent Bit를 배포하는 방법](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/Container-Insights-setup-logs-FluentBit.html#Container-Insights-FluentBit-troubleshoot)에 대해 자세히 알아보세요.

먼저, 다음 명령을 입력하여 Fluent Bit용으로 생성된 리소스를 확인할 수 있습니다. 각 노드에는 하나의 Pod가 있어야 합니다:

```bash hook=get-all
$ kubectl get all -n kube-system -l app.kubernetes.io/name=aws-for-fluent-bit
NAME                           READY   STATUS    RESTARTS   AGE
pod/aws-for-fluent-bit-jg4jr   1/1     Running   0          94s
pod/aws-for-fluent-bit-lvp9f   1/1     Running   0          95s
pod/aws-for-fluent-bit-q959s   1/1     Running   0          94s

NAME                         TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
service/aws-for-fluent-bit   ClusterIP   172.16.41.165   <none>        2020/TCP   96s

NAME                                DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR   AGE
daemonset.apps/aws-for-fluent-bit   3         3         3       3            3           <none>          96s
```

aws-for-fluent-bit의 ConfigMap은 각 노드의 `/var/log/containers/*.log` 디렉터리에 있는 파일의 내용을 CloudWatch 로그 그룹 `/eks-workshop/worker-fluentbit-logs`로 스트리밍하도록 구성되어 있습니다:

```bash hook=desc-cm
$ kubectl describe configmap -n kube-system -l app.kubernetes.io/name=aws-for-fluent-bit
Name:         aws-for-fluent-bit
Namespace:    kube-system
Labels:       app.kubernetes.io/instance=aws-for-fluent-bit
              app.kubernetes.io/managed-by=Helm
              app.kubernetes.io/name=aws-for-fluent-bit
              app.kubernetes.io/version=2.31.12.20231011
              helm.sh/chart=aws-for-fluent-bit-0.1.32
Annotations:  meta.helm.sh/release-name: aws-for-fluent-bit
              meta.helm.sh/release-namespace: kube-system

Data
====
fluent-bit.conf:
----
[SERVICE]
    HTTP_Server  On
    HTTP_Listen  0.0.0.0
    HTTP_PORT    2020
    Health_Check On
    HC_Errors_Count 5
    HC_Retry_Failure_Count 5
    HC_Period 5

    Parsers_File /fluent-bit/parsers/parsers.conf
[INPUT]
    Name              tail
    Tag               kube.*
    Path              /var/log/containers/*.log
    DB                /var/log/flb_kube.db
    multiline.parser  docker, cri
    Mem_Buf_Limit     5MB
    Skip_Long_Lines   On
    Refresh_Interval  10
[FILTER]
    Name                kubernetes
    Match               kube.*
    Kube_URL            https://kubernetes.default.svc.cluster.local:443
    Merge_Log           On
    Merge_Log_Key       data
    Keep_Log            On
    K8S-Logging.Parser  On
    K8S-Logging.Exclude On
    Buffer_Size         32k
[OUTPUT]
    Name                  cloudwatch_logs
    Match                 *
    region                us-west-2
    log_group_name        /aws/eks/eks-workshop/aws-fluentbit-logs-20250415195811907400000002
    log_stream_prefix     fluentbit-
...
```

`kubectl logs` 명령을 사용하여 Fluent Bit Pod 로그를 확인하면, 서비스에 대한 새로운 CloudWatch Log 그룹과 스트림이 생성되는 것을 관찰할 수 있습니다.

```bash hook=pods-log
$ kubectl logs daemonset.apps/aws-for-fluent-bit -n kube-system

Found 3 pods, using pod/aws-for-fluent-bit-4mnbw
AWS for Fluent Bit Container Image Version 2.28.4
Fluent Bit v1.9.9
* Copyright (C) 2015-2022 The Fluent Bit Authors
* Fluent Bit is a CNCF sub-project under the umbrella of Fluentd
* https://fluentbit.io

[2025/04/14 16:15:40] [ info] [fluent bit] version=1.9.9, commit=5fcfe330e5, pid=1
[2025/04/14 16:15:40] [ info] [storage] version=1.3.0, type=memory-only, sync=normal, checksum=disabled, max_chunks_up=128
[2025/04/14 16:15:40] [ info] [cmetrics] version=0.3.7
...
[2025/04/14 16:15:40] [ info] [filter:kubernetes:kubernetes.0] connectivity OK
[2025/04/14 16:15:40] [ info] [sp] stream processor started
[2025/04/14 16:15:40] [ info] [output:cloudwatch_logs:cloudwatch_logs.0] worker #0 started
...
[2025/04/14 16:16:01] [ info] [output:cloudwatch_logs:cloudwatch_logs.0] Creating log stream ui-8564fc5cfb-54llk.ui in log group /aws/eks/fluentbit-cloudwatch/workload/ui
[2025/04/14 16:16:01] [ info] [output:cloudwatch_logs:cloudwatch_logs.0] Log Group /aws/eks/fluentbit-cloudwatch/workload/ui not found. Will attempt to create it.
[2025/04/14 16:16:01] [ info] [output:cloudwatch_logs:cloudwatch_logs.0] Creating log group /aws/eks/fluentbit-cloudwatch/workload/ui
[2025/04/14 16:16:01] [ info] [output:cloudwatch_logs:cloudwatch_logs.0] Created log group /aws/eks/fluentbit-cloudwatch/workload/ui
[2025/04/14 16:16:01] [ info] [output:cloudwatch_logs:cloudwatch_logs.0] Creating log stream ui-8564fc5cfb-54llk.ui in log group /aws/eks/fluentbit-cloudwatch/workload/ui
[2025/04/14 16:16:01] [ info] [output:cloudwatch_logs:cloudwatch_logs.0] Created log stream ui-8564fc5cfb-54llk.ui
```

