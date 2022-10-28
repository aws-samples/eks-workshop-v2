---
title: "Scraping metrics using AWS Distro for OpenTelemetry"
sidebar_position: 60
---

To gather the metrics from the Amazon EKS Cluster, we will deploy the OpenTelemetryCollector Custom Resource Definition(CRD). The ADOT operator running on the EKS cluster detects the presence of or changes of the OpenTelemetryCollector resource.  For any such change, the ADOT Operator performs the following actions:

Verifies that all the required connections for these creation, update, or deletion requests to the Kubernetes API server are available.
Deploys ADOT Collector instances in the way the user expressed in the OpenTelemetryCollector resource configuration.

Let's now deploy the CRD using Kustomization to scrape the metrics and ingest them to Amazon Managed Service for Prometheus. As part of setting up the lab, we have deployed the Amazon Managed Service for Prometheus workspace and will use the workspace to store the metrics.

```file
observability/collecting-metrics/collecting-metrics-adot/opentelemetrycollector.yaml
```
This will cauase the adot collector to scrape Kubernetes endpoints and remote write them to Amazon Managed Service for Prometheus:

```bash timeout=180 hook=add-ingress hookTimeout=430
$ kubectl apply -k /workspace/modules/observability/metrics
```

Let's inspect the ADOT collector pod by running the below command:

```bash 
$ kubectl get pods -n adot-collector-kubeprometheus
NAME                              READY   STATUS    RESTARTS   AGE
adot-collector-6f6b8867f6-lpjb7   1/1     Running   2          11d
```




