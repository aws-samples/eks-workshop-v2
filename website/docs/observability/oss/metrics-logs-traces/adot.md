---
title: "Collecting metrics, logs and traces using ADOT"
sidebar_position: 10
---

In this lab we'll be storing metrics in an Amazon Managed Service for Prometheus workspace which is already created for you. You should be able to see it in the console:

<ConsoleButton url="https://console.aws.amazon.com/prometheus/home#/workspaces" service="aps" label="Open APS console"/>

To view the workspace, click on the **All Workspaces** tab on the left control panel. Select the workspace that starts with **eks-workshop** and you can view several tabs under the workspace such as rules management, alert manager etc.

Loki and Tempo were also deployed on the EKS cluster, we can check and confirm that they are running:

```bash
$ kubectl -n loki-system get pod
NAME         READY       STATUS       RESTARTS      AGE
loki-0       1/1         Running      0             5d21h
$ kubectl -n tempo-system get pod
NAME         READY       STATUS       RESTARTS      AGE
tempo-0      1/1         Running      0             6d2h
```

To gather the metrics, logs and traces from the Amazon EKS Cluster, we'll deploy a `OpenTelemetryCollector` custom resource. The ADOT operator running on the EKS cluster detects the presence of or changes of the this resource and for any such changes, the operator performs the following actions:

- Verifies that all the required connections for these creation, update, or deletion requests to the Kubernetes API server are available.
- Deploys ADOT collector instances in the way the user expressed in the `OpenTelemetryCollector` resource configuration.

Now, let's create resources to allow the ADOT collector the permissions it needed. We'll start with the ClusterRole that gives the collector permissions to access the Kubernetes API:

```file
manifests/modules/observability/oss/adot/clusterrole.yaml
```

We'll use the managed IAM policy `AmazonPrometheusRemoteWriteAccess` to provide the collector with the IAM permissions it needs via IAM Roles for Service Accounts:

```bash
$ aws iam list-attached-role-policies \
  --role-name $EKS_CLUSTER_NAME-adot-collector | jq .
{
  "AttachedPolicies": [
    {
      "PolicyName": "AmazonPrometheusRemoteWriteAccess",
      "PolicyArn": "arn:aws:iam::aws:policy/AmazonPrometheusRemoteWriteAccess"
    }
  ]
}
```

This IAM role will be added to the ServiceAccount for the collector:

```file
manifests/modules/observability/oss/adot/serviceaccount.yaml
```

Create the resources:

```bash hook=deploy-adot
$ kubectl kustomize ~/environment/eks-workshop/modules/observability/oss/adot \
  | envsubst | kubectl apply -f-
$ kubectl rollout status -n other daemonset/adot-collector --timeout=120s
```

The specification for the collector is too long to show here, but you can view it like so:

```bash
$ kubectl -n other get opentelemetrycollector adot -o yaml
```

Let's break this down in to sections to get a better understanding of what has been deployed. This is the OpenTelemetry collector configuration:

```bash
$ kubectl -n other get opentelemetrycollector adot -o jsonpath='{.spec.config}' | yq
```

This is configuring an OpenTelemetry pipeline with the following structure:

- Receivers
  - [Prometheus receiver](https://github.com/open-telemetry/opentelemetry-collector-contrib/blob/main/receiver/prometheusreceiver) designed to scrape metrics from targets that expose a Prometheus endpoint
  - [Filelog receiver](https://github.com/open-telemetry/opentelemetry-collector-contrib/blob/main/receiver/filelogreceiver) which tails and parses container logs from files on worker nodes
  - [OTLP Receiver](https://github.com/open-telemetry/opentelemetry-collector/tree/main/receiver/otlpreceiver) which receives data via HTTP or gRPC using OTLP format
- Processors
  - [Batch processor](https://github.com/open-telemetry/opentelemetry-collector/blob/main/processor/batchprocessor) which helps better compress the data and reduce the number of outgoing connections required to transmit the data
- Exporters
  - [Prometheus remote write exporter](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/exporter/prometheusremotewriteexporter) which sends metrics to a Prometheus remote write endpoint like AMP
  - [OTLP HTTP exporter](https://github.com/open-telemetry/opentelemetry-collector/blob/main/exporter/otlphttpexporter) and [OTLP gRPC exporter](https://github.com/open-telemetry/opentelemetry-collector/blob/main/exporter/otlpexporter) which exports logs and traces via HTTP and gRPC using OTLP format

This collector is also configured to run as a DaemonSet with one collector agent running on each worker node:

```bash
$ kubectl -n other get opentelemetrycollector adot -o jsonpath='{.spec.mode}{"\n"}'
```

We can confirm that by inspecting the ADOT collector Pods that are running:

```bash
$ kubectl get pods -n other
NAME                      READY      STATUS       RESTARTS      AGE
adot-collector-58mwb      1/1        Running      0             3d21h
adot-collector-czjg4      1/1        Running      0             3d21h
adot-collector-sjj8h      1/1        Running      0             3d21h
```

Since we want to use the `Instrumentation` custom resources (which were deployed after the applications) to [inject OpenTelemetry SDK environment variables](https://github.com/open-telemetry/opentelemetry-operator?tab=readme-ov-file#inject-opentelemetry-sdk-environment-variables-only), we will need redeploy the applications:

```bash
$ kubectl -n assets rollout restart deployment assets && \
  kubectl -n carts rollout restart deployment carts && \
  kubectl -n catalog rollout restart deployment catalog && \
  kubectl -n checkout rollout restart deployment checkout && \
  kubectl -n orders rollout restart deployment orders && \
  kubectl -n ui rollout restart deployment ui
deployment.apps/assets restarted
deployment.apps/carts restarted
deployment.apps/catalog restarted
deployment.apps/checkout restarted
deployment.apps/orders restarted
deployment.apps/ui restarted
```
