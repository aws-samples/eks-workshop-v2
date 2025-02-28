---
title: "Fluent Bit 사용하기"
sidebar_position: 30
---

파드에서 실행되는 Kubernetes 클러스터 컴포넌트들은 기본 로깅 메커니즘을 우회하여 `/var/log` 디렉토리 내의 파일에 기록합니다. Fluent Bit와 같은 노드 레벨 로깅 에이전트를 DaemonSet으로 각 노드에 배포하여 파드 레벨 로깅을 구현할 수 있습니다.

[Fluent Bit](https://fluentbit.io/)는 경량 로그 프로세서이자 포워더로, 다양한 소스로부터 데이터와 로그를 수집하고 필터로 보강한 뒤 CloudWatch, Kinesis Data Firehose, Kinesis Data Streams, Amazon OpenSearch Service와 같은 여러 대상으로 전송할 수 있게 해줍니다.

AWS는 CloudWatch Logs와 Kinesis Data Firehose 모두를 위한 플러그인이 포함된 Fluent Bit 이미지를 제공합니다. [AWS for Fluent Bit](https://github.com/aws/aws-for-fluent-bit) 이미지는 [Amazon ECR Public Gallery](https://gallery.ecr.aws/aws-observability/aws-for-fluent-bit)에서 사용할 수 있습니다.

다음 섹션에서는 Fluent Bit 에이전트가 DaemonSet으로 실행되어 컨테이너/파드 로그를 CloudWatch Logs로 전송하는 것을 어떻게 확인하는지 볼 수 있습니다.

먼저, 다음 명령어를 입력하여 Fluent Bit용으로 생성된 리소스를 확인할 수 있습니다. 각 노드에는 하나의 파드가 있어야 합니다:

```bash
$ kubectl get all -n aws-for-fluent-bit
NAME                           READY   STATUS    RESTARTS   AGE
pod/aws-for-fluent-bit-vfsbe   1/1     Running   0          99m
pod/aws-for-fluent-bit-kmvnk   1/1     Running   0          99m
pod/aws-for-fluent-bit-rxhs7   1/1     Running   0          100m

NAME                                DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR   AGE
daemonset.apps/aws-for-fluent-bit   2         2         2       2            2           <none>          104m
```

aws-for-fluent-bit용 ConfigMap은 각 노드의 `/var/log/containers/*.log` 디렉토리에 있는 파일의 내용을 CloudWatch 로그 그룹 `/eks-workshop/worker-fluentbit-logs`로 스트리밍하도록 구성되어 있습니다:

```bash
$ kubectl describe configmaps -n aws-for-fluent-bit
Name:         aws-for-fluent-bit
Namespace:    aws-for-fluent-bit
Labels:       app.kubernetes.io/instance=aws-for-fluent-bit
              app.kubernetes.io/managed-by=Helm
              app.kubernetes.io/name=aws-for-fluent-bit
              app.kubernetes.io/version=2.21.5
              helm.sh/chart=aws-for-fluent-bit-0.1.18
Annotations:  meta.helm.sh/release-name: aws-for-fluent-bit
              meta.helm.sh/release-namespace: aws-for-fluent-bit

Data
====
fluent-bit.conf:
----
[SERVICE]
    Parsers_File /fluent-bit/parsers/parsers.conf

[INPUT]
    Name              tail
    Tag               kube.*
    Path              /var/log/containers/*.log
    DB                /var/log/flb_kube.db
    Parser            docker
    Docker_Mode       On
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
[OUTPUT]
    Name                  cloudwatch
    Match                 *
    region                us-east-1
    log_group_name        /eks-workshop/worker-fluentbit-logs
    log_stream_prefix     fluentbit-
    auto_create_group     true

...........

```