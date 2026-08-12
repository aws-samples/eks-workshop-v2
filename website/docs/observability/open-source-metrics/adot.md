---
title: "Collecting metrics with the CloudWatch agent"
sidebar_position: 10
---

In this lab we'll be storing metrics in an Amazon Managed Service for Prometheus workspace which is already created for you. You should be able to see it in the console:

<ConsoleButton url="https://console.aws.amazon.com/prometheus/home#/workspaces" service="aps" label="Open APS console"/>

To view the workspace, click on the **All Workspaces** tab on the left control panel. Select the workspace that starts with **eks-workshop** and you can view several tabs under the workspace such as rules management, alert manager etc.

To gather metrics from the Amazon EKS cluster we'll use the [Amazon CloudWatch Observability EKS add-on](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/install-CloudWatch-Observability-EKS-addon.html), which deploys the CloudWatch agent. The agent runs an embedded OpenTelemetry collector, and because that collector includes the [Prometheus receiver](https://github.com/open-telemetry/opentelemetry-collector-contrib/blob/main/receiver/prometheusreceiver/README.md) and the [Prometheus Remote Write exporter](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/exporter/prometheusremotewriteexporter), we can point the add-on at Amazon Managed Service for Prometheus instead of CloudWatch.

:::info
There is nothing special about the CloudWatch agent here. Any OpenTelemetry-compatible collector configured with a Prometheus receiver, the `sigv4auth` extension and the Prometheus Remote Write exporter can send metrics to Amazon Managed Service for Prometheus. We use the add-on because it is a managed, supported way to run that collector without deploying and maintaining a collector or operator yourself.
:::

### Grant the CloudWatch agent permissions

The CloudWatch agent needs IAM permissions to remote-write metrics to your Amazon Managed Service for Prometheus workspace. We'll grant them using [Amazon EKS Pod Identity](https://docs.aws.amazon.com/eks/latest/userguide/pod-identities.html), which lets a Kubernetes service account assume an IAM role without any static credentials. The [EKS Pod Identity Agent](https://docs.aws.amazon.com/eks/latest/userguide/pod-identities.html) add-on, a prerequisite for Pod Identity, has already been installed on the cluster for you by `prepare-environment`.

Create an IAM role that the CloudWatch agent can assume. The trust policy allows the EKS Pod Identity service principal, and we attach the AWS managed `AmazonPrometheusRemoteWriteAccess` policy for AMP ingestion along with `CloudWatchAgentServerPolicy` for the agent's baseline operation:

```bash
$ aws iam create-role \
  --role-name $EKS_CLUSTER_NAME-cloudwatch-agent \
  --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"pods.eks.amazonaws.com"},"Action":["sts:AssumeRole","sts:TagSession"]}]}'
$ aws iam attach-role-policy \
  --role-name $EKS_CLUSTER_NAME-cloudwatch-agent \
  --policy-arn arn:aws:iam::aws:policy/AmazonPrometheusRemoteWriteAccess
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

### Configure the add-on to write to AMP

We provide the add-on with an OpenTelemetry pipeline that scrapes Prometheus metrics from the cluster and remote-writes them to your workspace:

```file
manifests/modules/observability/oss-metrics/cwagent-amp/cloudwatch-agent-amp.yaml
```

A few parts of this configuration matter. The `prometheusremotewrite/amp` exporter sends metrics to the AMP workspace's remote-write endpoint, and the `sigv4auth` extension signs those requests with the credentials the agent obtains through Pod Identity. The Prometheus `scrape_configs` collect application metrics from annotated pods (`kubernetes-pods`) and cluster metrics from the `kubelet` and `cadvisor` endpoints on each node.

The pipeline is attached to the `cloudwatch-agent-cluster-scraper` agent, a single-replica Deployment, rather than the global agent configuration. The add-on also runs the CloudWatch agent as a DaemonSet on every node. If we attached the remote-write pipeline globally, every node would scrape and write the same series, and AMP would reject the duplicate samples. Scoping it to the single cluster-scraper means each series is written exactly once.

Install the `amazon-cloudwatch-observability` add-on with this configuration. We use `envsubst` to substitute your workspace endpoint and Region into the file before handing it to the add-on:

```bash hook=deploy-adot
$ envsubst '$AMP_ENDPOINT $AWS_REGION' \
  < ~/environment/eks-workshop/modules/observability/oss-metrics/cwagent-amp/cloudwatch-agent-amp.yaml \
  > /tmp/cloudwatch-agent-amp.yaml
$ aws eks create-addon \
  --cluster-name $EKS_CLUSTER_NAME \
  --addon-name amazon-cloudwatch-observability \
  --configuration-values file:///tmp/cloudwatch-agent-amp.yaml
$ aws eks wait addon-active \
  --cluster-name $EKS_CLUSTER_NAME \
  --addon-name amazon-cloudwatch-observability
```

The add-on deploys the CloudWatch agent into the `amazon-cloudwatch` namespace. Confirm the pods are running:

```bash
$ kubectl get pods -n amazon-cloudwatch
NAME                                                READY   STATUS    RESTARTS   AGE
cloudwatch-agent-8xk2p                              1/1     Running   0          72s
cloudwatch-agent-df9wz                              1/1     Running   0          72s
cloudwatch-agent-cluster-scraper-6dfdc8f88-458kl    1/1     Running   0          72s
fluent-bit-2s7zn                                    1/1     Running   0          72s
fluent-bit-krl6t                                    1/1     Running   0          72s
```

Notice the mix of components the add-on manages for you: the `cloudwatch-agent` DaemonSet, the single `cloudwatch-agent-cluster-scraper` Deployment that runs our AMP pipeline, and the `fluent-bit` DaemonSet, all open source projects packaged and supported as a managed add-on.
