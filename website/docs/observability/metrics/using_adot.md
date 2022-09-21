---
title: "Scraping metrics using AWS Distro for OpenTelemetry"
sidebar_position: 30
---

Let's create a service account adot-collector that has the permissions to write metrics to Amazon Managed Service for Prometheus

```bash timeout=180 hook=add-ingress hookTimeout=430
$ eksctl create iamserviceaccount \
    --name adot-collector \
    --namespace default \
    --cluster my-cluster \
    --attach-policy-arn arn:aws:iam::aws:policy/AmazonPrometheusRemoteWriteAccess \
    --approve \
    --override-existing-serviceaccounts
```

Let's now deploy the ADOT collector using Kustomization to scrape the metrics and ingest them to Amazon Managed Service for Prometheus

```file
observability/metrics/adot.yaml
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