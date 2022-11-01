---
title: "Stream Pod logs to CloudWatch"
sidebar_position: 30
---

For Kubernetes cluster components that run in pods, these write to files inside the <i>/var/log</i> directory, bypassing the default logging mechanism. We can implement pod-level logging by deploying a node-level logging agent as a DaemonSet on each node, such as Fluent Bit. 

[Fluent Bit](https://fluentbit.io/) is a lightweight log processor and forwarder that allows you to collect data and logs from different sources, enrich them with filters and send them to multiple destinations like CloudWatch, Kinesis Data Firehose, Kinesis Data Streams and Amazon OpenSearch Service.

AWS provides a Fluent Bit image with plugins for both CloudWatch Logs and Kinesis Data Firehose. The [AWS for Fluent Bit](https://github.com/aws/aws-for-fluent-bit) image is available on the Amazon ECR Public Gallery. 

In the following section, you will see how to deploy Fluent Bit agent as a daemonSet to send the containers / pods logs to CloudWatch Logs.

1. When using EKS Blueprint, you can enable 'aws_for_fluentbit' add-on to deploy the Fluent Bit agent. The agent is configured to stream the worker node logs to CloudWatch Logs by default. It can be further configured to stream the logs to additional destinations like Kinesis Data Firehose, Kinesis Data Streams and Amazon OpenSearch Service by passing the custom values.yaml. 

  For Manual installation see this [Helm Chart](https://github.com/aws/eks-charts/tree/master/stable/aws-for-fluent-bit) for more detail.

  ```bash
  $ less terraform/modules/cluster/addons.tf
  .....
    enable_aws_for_fluentbit               = true
  ```

  You can optionally customize the Helm chart that deploys aws_for_fluentbit via the following configuration

  ```bash
  $ less terraform/modules/cluster/addons.tf
  .....
    enable_aws_for_fluentbit = true
    aws_for_fluentbit_irsa_policies = ["IAM Policies"] # Add list of additional policies to IRSA to enable access to Kinesis, OpenSearch etc.
    aws_for_fluentbit_helm_config = {
      name                                      = "aws-for-fluent-bit"
      chart                                     = "aws-for-fluent-bit"
      repository                                = "https://aws.github.io/eks-charts"
      version                                   = "0.1.0"
      namespace                                 = "logging"
      aws_for_fluent_bit_cw_log_group           = "/${local.cluster_id}/worker-fluentbit-logs" # Optional
      aws_for_fluentbit_cwlog_retention_in_days = 90
      create_namespace                          = true
      values = [templatefile("${path.module}/values.yaml", {
        region                          = data.aws_region.current.name,
        aws_for_fluent_bit_cw_log_group = "/${local.cluster_id}/worker-fluentbit-logs"
      })]
      set = [
        {
          name  = "nodeSelector.kubernetes\\.io/os"
          value = "linux"
        }
      ]
    }

  ```

2. Validate the fluent-bit deployment by entering the following command. Each node should have one pod 

  ```bash
  $ kubectl get all -n aws-for-fluent-bit
  NAME                           READY   STATUS    RESTARTS   AGE
  pod/aws-for-fluent-bit-kmvnk   1/1     Running   0          99m
  pod/aws-for-fluent-bit-rxhs7   1/1     Running   0          100m

  NAME                                DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR   AGE
  daemonset.apps/aws-for-fluent-bit   2         2         2       2            2           <none>          104m
  ```

3. Verify the ConfigMap for aws-for-fluent-bit, it is configured to stream the _/var/log/containers/*.log_ from each nodes to CloudWatch log group '/eks-workshop-cluster/worker-fluentbit-logs'

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
      log_group_name        /eks-workshop-cluster/worker-fluentbit-logs
      log_stream_prefix     fluentbit-
      auto_create_group     true

  ...........    

  ```
