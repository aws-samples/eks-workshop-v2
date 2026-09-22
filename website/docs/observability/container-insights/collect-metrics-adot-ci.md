---
title: "Cluster metrics"
sidebar_position: 10
---

We're going to enable CloudWatch Container Insights for our EKS cluster using the [Amazon CloudWatch Observability EKS add-on](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/install-CloudWatch-Observability-EKS-addon.html). The add-on deploys the CloudWatch agent, which collects metrics related to various aspects of the cluster such as nodes, pods and containers and sends them to CloudWatch.

Under the hood the CloudWatch agent is built on [OpenTelemetry](https://opentelemetry.io/). When you enable OTel Container Insights the agent runs an embedded OpenTelemetry pipeline: the [AWS Container Insights Receiver](https://github.com/open-telemetry/opentelemetry-collector-contrib/blob/main/receiver/awscontainerinsightreceiver/README.md) gathers node and container telemetry, and the [AWS CloudWatch EMF Exporter](https://github.com/open-telemetry/opentelemetry-collector-contrib/blob/main/exporter/awsemfexporter/README.md) converts it to [CloudWatch Embedded Metric Format (EMF)](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch_Embedded_Metric_Format_Specification.html) and sends it to CloudWatch Logs, where the metrics surface in the `ContainerInsights` namespace. The add-on manages this pipeline for you — there is no collector manifest, Helm chart or DaemonSet to deploy and maintain. The agent runs as a DaemonSet so that one pod runs on each node in the cluster.

### Grant the CloudWatch agent permissions

The CloudWatch agent needs IAM permissions to send metrics and logs to CloudWatch. We'll grant them using [Amazon EKS Pod Identity](https://docs.aws.amazon.com/eks/latest/userguide/pod-identities.html), which lets a Kubernetes service account assume an IAM role without any static credentials.

The [EKS Pod Identity Agent](https://docs.aws.amazon.com/eks/latest/userguide/pod-identities.html) add-on, a prerequisite for Pod Identity, has already been installed on the cluster for you by `prepare-environment`.

Create an IAM role that the CloudWatch agent can assume. The trust policy allows the EKS Pod Identity service principal, and we attach the AWS managed `CloudWatchAgentServerPolicy`:

```bash
$ aws iam create-role \
  --role-name $EKS_CLUSTER_NAME-cloudwatch-agent \
  --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"pods.eks.amazonaws.com"},"Action":["sts:AssumeRole","sts:TagSession"]}]}'
$ aws iam attach-role-policy \
  --role-name $EKS_CLUSTER_NAME-cloudwatch-agent \
  --policy-arn arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy
```

Associate the role with the `cloudwatch-agent` service account that the add-on will create in the `amazon-cloudwatch` namespace:

```bash
$ aws eks create-pod-identity-association \
  --cluster-name $EKS_CLUSTER_NAME \
  --namespace amazon-cloudwatch \
  --service-account cloudwatch-agent \
  --role-arn arn:aws:iam::$AWS_ACCOUNT_ID:role/$EKS_CLUSTER_NAME-cloudwatch-agent
```

### Enable Container Insights

Now install the `amazon-cloudwatch-observability` add-on with OTel Container Insights enabled. This is the same add-on installed whether you use the console or the AWS CLI, and it deploys and configures the CloudWatch agent for you:

```bash
$ aws eks create-addon \
  --cluster-name $EKS_CLUSTER_NAME \
  --addon-name amazon-cloudwatch-observability \
  --configuration-values '{"otelContainerInsights":{"enabled":true}}'
$ aws eks wait addon-active \
  --cluster-name $EKS_CLUSTER_NAME \
  --addon-name amazon-cloudwatch-observability
```

:::note
The `otelContainerInsights.enabled` configuration turns on OTel Container Insights. It is not enabled by default.
:::

The add-on deploys the CloudWatch agent as a DaemonSet in the `amazon-cloudwatch` namespace. Confirm the agent pods are running:

```bash hook=metrics
$ kubectl get pods -n amazon-cloudwatch -l app.kubernetes.io/name=cloudwatch-agent
NAME                     READY   STATUS    RESTARTS   AGE
cloudwatch-agent-4frxx   1/1     Running   0          31s
cloudwatch-agent-5rvpc   1/1     Running   0          31s
cloudwatch-agent-tptl7   1/1     Running   0          31s
```

Because the agent assumes the IAM role through Pod Identity, it can send metrics to CloudWatch immediately. To view them, open the CloudWatch console and navigate to Container Insights:

:::tip
It may take a 2-3 minutes for data to start appearing in CloudWatch.
:::

<ConsoleButton url="https://console.aws.amazon.com/cloudwatch/home#container-insights:performance/EKS:Cluster?~(query~(controls~(CW*3a*3aEKS.cluster~(~'eks-workshop)))~context~())" service="cloudwatch" label="Open CloudWatch console"/>

![ContainerInsightsConsole](/docs/observability/container-insights/container-insights-metrics-console.webp)

You can take some time to explore around the console to see the various ways that metrics are presented such as by cluster, namespace or pod.
