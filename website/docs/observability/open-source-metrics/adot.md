---
title: "Scraping metrics using AWS Distro for OpenTelemetry"
sidebar_position: 10
---

In this lab we'll be storing metrics in an Amazon Managed Service for Prometheus workspace which is already created for you. You should be able to see it in the console:

<ConsoleButton url="https://console.aws.amazon.com/prometheus/home#/workspaces" service="aps" label="Open APS console"/>

To view the workspace, click on the **All Workspaces** tab on the left control panel. Select the workspace that starts with **eks-workshop** and you can view several tabs under the workspace such as rules management, alert manager etc.

To gather the metrics from the Amazon EKS Cluster, we'll deploy a `OpenTelemetryCollector` custom resource. The ADOT operator running on the EKS cluster detects the presence of or changes of the this resource and for any such changes, the operator performs the following actions:

- Verifies that all the required connections for these creation, update, or deletion requests to the Kubernetes API server are available.
- Deploys ADOT collector instances in the way the user expressed in the `OpenTelemetryCollector` resource configuration.

Now, let's create resources to allow the ADOT collector the permissions it needed. We'll start with the ClusterRole that gives the collector permissions to access the Kubernetes API:

::yaml{file="manifests/modules/observability/oss-metrics/adot/clusterrole.yaml" paths="rules.0,rules.1,rules.2"}

1. This core API group `""` gives the role permissions to access core Kubernetes resources listed under `resources` using the actions specified under `verbs` for metrics collection
2. This extensions API group `extensions` gives the role permissions to access ingress resources using the actions specified under `verbs` for network traffic metrics collection
3. The `nonResourceURLs` gives the role permissions to access the `/metrics` endpoint on the Kubernetes API server using the action specified under `verbs` for cluster-level operational metrics collection

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
manifests/modules/observability/oss-metrics/adot/serviceaccount.yaml
```

Create the resources:

```bash hook=deploy-adot
$ kubectl kustomize ~/environment/eks-workshop/modules/observability/oss-metrics/adot \
  | envsubst | kubectl apply -f-
$ kubectl rollout status -n other deployment/adot-collector --timeout=120s
```

The specification for the collector is too long to show here, but you can view it like so:

```bash
$ kubectl -n other get opentelemetrycollector adot -o yaml
```

Let's break this down in to sections to get a better understanding of what has been deployed. This is the OpenTelemetry collector configuration:

```bash
$ kubectl -n other get opentelemetrycollector adot -o jsonpath='{.spec.config}' | jq
```

This is configuring an OpenTelemetry pipeline with the following structure:

- Receivers
  - [Prometheus receiver](https://github.com/open-telemetry/opentelemetry-collector-contrib/blob/main/receiver/prometheusreceiver/README.md) designed to scrape metrics from targets that expose a Prometheus endpoint
- Processors
  - None in this pipeline
- Exporters
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
