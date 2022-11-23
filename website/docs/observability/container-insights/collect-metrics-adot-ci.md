---
title: "Enabling Container Insights Using AWS Distro for OpenTelemetry"
sidebar_position: 10
---

In this lab we will walk through how to enable CloudWatch Container Insights metrics with the ADOT Collector for an EKS cluster.

The first thing we need to do is create resources to allow the ADOT collector the permissions it needed. We'll start with the ClusterRole that gives the collector permissions to access the Kubernetes API:

```file
observability/container-insights/adot/clusterrole.yaml
```

We'll use the managed IAM policy `CloudWatchAgentServerPolicy` to provide to the collector with the IAM permissions it needed via IAM Roles for Service Accounts:

```bash
$ aws iam list-attached-role-policies \
  --role-name eks-workshop-cluster-adot-collector-ci | jq .
{
  "AttachedPolicies": [
    {
      "PolicyName": "CloudWatchAgentServerPolicy",
      "PolicyArn": "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
    }
  ]
}
```

This will be added to the ServiceAccount for the collector:

```file
observability/container-insights/adot/serviceaccount.yaml
```

Create these resources:

```bash
$ kubectl apply -k /workspace/modules/observability/container-insights/adot
```

Next we'll create the `OpenTelemetryCollector` object. This needs some extra variables provided from our environment so we'll pass it through `envsubst` before directly applying it.

```bash
$ envsubst < <(cat /workspace/modules/observability/container-insights/adot/opentelemetrycollector.yaml) | kubectl apply -f -
```

The specification for the collector is too long to show here, but you can view it like so:

```bash
$ kubectl -n other get opentelemetrycollector adot-container-ci
```

Lets break this down in to sections to get a better understanding of what has been deployed. This is the OpenTelemetry collector configuration:

```bash
$ kubectl -n other get opentelemetrycollector adot-container-ci -o jsonpath='{.spec.config}'
```

This is configuring an OpenTelemetry pipeline with the following structure:

* Receivers
  - [Container Insights receiver](https://github.com/open-telemetry/opentelemetry-collector-contrib/blob/main/receiver/awscontainerinsightreceiver/README.md) designed to collect performance log events using the Embedded Metric Format
* Processors
  - Batch the metrics in to 60 second intervals
* Exporters
  - [CloudWatch EMF](https://github.com/open-telemetry/opentelemetry-collector-contrib/blob/main/exporter/awsemfexporter/README.md) exporter which sends metrics to the CloudWatch API

This collector is also configured to run as a DaemonSet with a collector agent running on each node:

```bash
$ kubectl -n other get opentelemetrycollector adot-container-ci -o jsonpath='{.spec.mode}{"\n"}'
```

We can confirm that by inspecting the ADOT collector Pods collecting Container Insights metrics that are running:

```bash
$ kubectl get pods -n other
NAME                               READY   STATUS    RESTARTS   AGE
adot-container-ci-collector-5lp5g  1/1     Running   0          15s
adot-container-ci-collector-ctvgs  1/1     Running   0          15s
```

If the output of this command includes multiple pods in the `Running` state as shown above, the collector is running and collecting metrics from the cluster. The collector creates a log group named *aws/containerinsights/**cluster-name**/performance* and sends the metric data as performance log events in EMF format.