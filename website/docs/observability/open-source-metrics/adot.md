---
title: "Scraping metrics using AWS Distro for OpenTelemetry"
sidebar_position: 10
---

To gather the metrics from the Amazon EKS Cluster, we'll deploy a `OpenTelemetryCollector` custom resource. The ADOT operator running on the EKS cluster detects the presence of or changes of the this resource and for any such changes, the operator performs the following actions:

- Verifies that all the required connections for these creation, update, or deletion requests to the Kubernetes API server are available.
- Deploys ADOT collector instances in the way the user expressed in the `OpenTelemetryCollector` resource configuration.

Now, let's create resources to allow the ADOT collector the permissions it needed. We'll start with the ClusterRole that gives the collector permissions to access the Kubernetes API:

```file
observability/oss-metrics/adot/clusterrole.yaml
```

We'll use the managed IAM policy `AmazonPrometheusRemoteWriteAccess` to provide the collector with the IAM permissions it needs via IAM Roles for Service Accounts:

```bash
$ aws iam list-attached-role-policies \
  --role-name eks-workshop-adot-collector | jq .
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
observability/oss-metrics/adot/serviceaccount.yaml
```

Create the resources:

```bash
$ kubectl apply -k /workspace/modules/observability/oss-metrics/adot
```

The specification for the collector is too long to show here, but you can view it like so:

```bash
$ kubectl -n other get opentelemetrycollector adot
```

Let's break this down in to sections to get a better understanding of what has been deployed. This is the OpenTelemetry collector configuration:

```bash
$ kubectl -n other get opentelemetrycollector adot -o jsonpath='{.spec.config}'
```

This is configuring an OpenTelemetry pipeline with the following structure:

* Receivers
  - [Prometheus receiver](https://github.com/open-telemetry/opentelemetry-collector-contrib/blob/main/receiver/prometheusreceiver/README.md) designed to scrape metrics from targets that expose a Prometheus endpoint
* Processors
  - None in this pipeline
* Exporters
  - [Prometheus remote write exporter](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/exporter/prometheusremotewriteexporter) which sends metrics to a Prometheus remote write endpoint like AMP

This collector is also configured to run as a Deployment with one collector agent running:

```bash
$ kubectl -n other get opentelemetrycollector adot -o jsonpath='{.spec.mode}{"\n"}'
```

We can confirm that by inspecting the ADOT collector Pods that are running:

```bash 
$ kubectl get pods -n other
NAME                              READY   STATUS    RESTARTS   AGE
adot-collector-6f6b8867f6-lpjb7   1/1     Running   2          11d
```
