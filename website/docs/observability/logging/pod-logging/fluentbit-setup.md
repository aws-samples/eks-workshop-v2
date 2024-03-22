---
title: "Using Fluent Bit"
sidebar_position: 30
---

For Kubernetes cluster components that run in pods, these write to files inside the `/var/log` directory, bypassing the default logging mechanism. We can implement pod-level logging by deploying a node-level logging agent as a DaemonSet on each node, such as Fluent Bit.

[Fluent Bit](https://fluentbit.io/) is a lightweight log processor and forwarder that allows you to collect data and logs from different sources, enrich them with filters and send them to multiple destinations like CloudWatch, Kinesis Data Firehose, Kinesis Data Streams and Amazon OpenSearch Service.

AWS provides a Fluent Bit image with plugins for both CloudWatch Logs and Kinesis Data Firehose. The [AWS for Fluent Bit](https://github.com/aws/aws-for-fluent-bit) image is available on the [Amazon ECR Public Gallery](https://gallery.ecr.aws/aws-observability/aws-for-fluent-bit).

In the following section, you will see how to validate Fluent Bit agent is running as a daemonSet to send the containers / pods logs to CloudWatch Logs.

First, we can validate the resources created for Fluent Bit by entering the following command. Each node should have one pod:

```bash
$ kubectl get all -n aws-for-fluent-bit
NAME                           READY   STATUS    RESTARTS   AGE
pod/aws-for-fluent-bit-vfsbe   1/1     Running   0          99m
pod/aws-for-fluent-bit-kmvnk   1/1     Running   0          99m
pod/aws-for-fluent-bit-rxhs7   1/1     Running   0          100m

NAME                                DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR   AGE
daemonset.apps/aws-for-fluent-bit   2         2         2       2            2           <none>          104m
```

The ConfigMap for aws-for-fluent-bit is configured to stream the contents of files in the directory `/var/log/containers/*.log` from each node to the CloudWatch log group `/eks-workshop/worker-fluentbit-logs`:

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
