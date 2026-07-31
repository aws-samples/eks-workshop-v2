---
title: "Amazon Managed Grafana Integration"
sidebar_position: 40
---
Amazon CloudWatch OpenTelemetry metrics appear as a native data source in Amazon Managed Grafana. This means you can query both OpenTelemetry ingested and enriched AWS vended metrics in a single pane of glass and build dashboards in Grafana.

**Access Grafana**

Retrieve the Grafana URL and credentials (see [Accessing Grafana](https://eksworkshop.com/docs/observability/open-source-metrics/accessing-grafana)):

```bash
kubectl get ingress -n grafana grafana -o=jsonpath='{.status.loadBalancer.ingress[0].hostname}{"\n"}'
kubectl get -n grafana secrets/grafana -o=jsonpath='{.data.admin-user}' | base64 -d; printf "\n"
kubectl get -n grafana secrets/grafana -o=jsonpath='{.data.admin-password}' | base64 -d; printf "\n"
```

**Configure the AMP Data Source**

After logging into Grafana, manually add the Amazon Managed Service for Prometheus data source:

1. Go to **Connections** → **Data sources** → **Add data source**
2. Select **Amazon Managed Service for Prometheus**
3. Set URL to `https://monitoring.<region>.amazonaws.com`
4. Set **Service Provider** to `monitoring`
5. Set **Region** to your AWS Region
6. Choose **Default Credential Chain** as authentication provider
7. Click **Save & test**

Refer to the official documentation: [CloudWatch PromQL](https://docs.aws.amazon.com/grafana/latest/userguide/cloudwatch-promql.html)

**Files Modified**

| File | Change |
|------|--------|
| `manifests/modules/observability/otlp-metrics/.workshop/terraform/main.tf` | Added Pod Identity agent, IAM role, Pod Identity association, CloudWatch observability add-on (OTLP metrics only), telemetry enrichment, OTel enrichment |
| `manifests/modules/observability/otlp-metrics/.workshop/cleanup.sh` | Added cleanup for OTel enrichment and telemetry enrichment |
| `lab/iam/policies/labs1.yaml` | Added `observabilityadmin:StartTelemetryEnrichment`, `cloudwatch:StartOTelEnrichment` permissions |
