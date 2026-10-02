# OTLP Metrics Module

This module provisions the infrastructure needed to collect OTLP-based Container Insights metrics from an EKS cluster using the `amazon-cloudwatch-observability` EKS managed add-on.

## What's Included

### EKS Add-ons

| Add-on | Purpose |
|--------|---------|
| `eks-pod-identity-agent` | Enables Pod Identity for IAM role association |
| `amazon-cloudwatch-observability` | Collects infrastructure metrics via OTLP and sends them to CloudWatch |

### CloudWatch Observability Configuration

The add-on is configured for **metrics-only collection** (no logs, no application tracing):

| Feature | Status | Description |
|---------|--------|-------------|
| OTel Container Insights | Enabled | Collects infrastructure metrics (CPU, memory, network, disk) via OTLP |
| OTel CI Logs | Disabled | OTEL-native log pipelines are turned off |
| Container Logs (Fluent Bit) | Disabled | No Fluent Bit DaemonSet deployed |
| Application Signals | Disabled | No auto-instrumentation for app telemetry |

### IAM Resources

| Resource | Purpose |
|----------|---------|
| IAM Role (`{cluster}-cw-observability`) | Pod Identity role with `CloudWatchAgentServerPolicy` |
| Pod Identity Association | Links the IAM role to `amazon-cloudwatch/cloudwatch-agent` service account |

### OTel Enrichment (Account-Level)

| Resource | Purpose |
|----------|---------|
| Telemetry Enrichment | Enables resource tags on telemetry data (via `aws observabilityadmin start-telemetry-enrichment`) |
| OTel Enrichment | Enriches AWS vended metrics with resource ARN and tags, making them queryable via PromQL (via `aws cloudwatch start-otel-enrichment`) |

### AWS Load Balancer Controller

Installed via `eks_blueprints_addons` module for load balancer provisioning support.

## IAM Permissions Required

The IDE role (`{cluster}-ide-role`) requires these permissions (defined in `lab/iam/policies/labs1.yaml`):

| Action | Purpose |
|--------|---------|
| `observabilityadmin:StartTelemetryEnrichment` | Enable resource tags on telemetry |
| `cloudwatch:StartOTelEnrichment` | Enable OTel enrichment for vended metrics |
| `iam:CreateServiceLinkedRole` | Create service-linked role for Resource Explorer (already in `iam.yaml`) |

## Dependency Chain

```
eks-pod-identity-agent
    └── IAM Role (Pod Identity trust)
        └── Pod Identity Association (amazon-cloudwatch/cloudwatch-agent)
            └── amazon-cloudwatch-observability add-on
                    (metrics only, no logs/signals)

telemetry_enrichment (aws observabilityadmin start-telemetry-enrichment)
    └── otel_enrichment (aws cloudwatch start-otel-enrichment)
```

## Cleanup

The cleanup script (`.workshop/cleanup.sh`) handles resources not managed by Terraform:

1. Deletes the `application-metrics-collector` AmazonCloudWatchAgent CRD
2. Deletes any `load-generator` pod created during the lab
3. Disables OTel enrichment (`aws cloudwatch stop-otel-enrichment`)
4. Disables resource tags on telemetry (`aws observabilityadmin stop-telemetry-enrichment`)

Terraform-managed resources (add-ons, IAM role, Pod Identity association) are destroyed automatically by the `reset-environment` script via `terraform destroy`.

## Usage

```bash
prepare-environment observability/otlp-metrics
```

## Configure CloudWatch Agent for Custom Metrics Collection

Deploy the CloudWatch Agent CRD to scrape Prometheus metrics from application workloads:

```bash
export CWA_IMAGE=$(kubectl get daemonset -n amazon-cloudwatch cloudwatch-agent -o jsonpath='{.spec.template.spec.containers[0].image}')
kubectl kustomize ~/environment/eks-workshop/modules/observability/otlp-metrics/otel | envsubst | kubectl apply -f -
```

## Generate Application Load

To produce application metrics, deploy the load generator (see [Application Metrics](https://eksworkshop.com/docs/observability/open-source-metrics/application-metrics) for reference):

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: load-generator
  namespace: other
spec:
  containers:
  - name: artillery
    image: artilleryio/artillery:2.0.0-31
    args:
    - "run"
    - "-t"
    - "http://ui.ui.svc"
    - "/scripts/scenario.yml"
    volumeMounts:
    - name: scripts
      mountPath: /scripts
  initContainers:
  - name: setup
    image: public.ecr.aws/aws-containers/retail-store-sample-utils:load-gen.1.2.1
    command:
    - bash
    args:
    - -c
    - "cp /artillery/* /scripts"
    volumeMounts:
    - name: scripts
      mountPath: "/scripts"
  volumes:
  - name: scripts
    emptyDir: {}
EOF
```

## Access Grafana

Retrieve the Grafana URL and credentials (see [Accessing Grafana](https://eksworkshop.com/docs/observability/open-source-metrics/accessing-grafana)):

```bash
kubectl get ingress -n grafana grafana -o=jsonpath='{.status.loadBalancer.ingress[0].hostname}{"\n"}'
kubectl get -n grafana secrets/grafana -o=jsonpath='{.data.admin-user}' | base64 -d; printf "\n"
kubectl get -n grafana secrets/grafana -o=jsonpath='{.data.admin-password}' | base64 -d; printf "\n"
```

## Configure the AMP Data Source

After logging into Grafana, manually add the Amazon Managed Service for Prometheus data source:

1. Go to **Connections** → **Data sources** → **Add data source**
2. Select **Amazon Managed Service for Prometheus**
3. Set URL to `https://monitoring.<region>.amazonaws.com`
4. Set **Service Provider** to `monitoring`
5. Set **Region** to your AWS Region
6. Choose **Default Credential Chain** as authentication provider
7. Click **Save & test**

Refer to the official documentation: [CloudWatch PromQL](https://docs.aws.amazon.com/grafana/latest/userguide/cloudwatch-promql.html)

## Files Modified

| File | Change |
|------|--------|
| `manifests/modules/observability/otlp-metrics/.workshop/terraform/main.tf` | Added Pod Identity agent, IAM role, Pod Identity association, CloudWatch observability add-on (OTLP metrics only), telemetry enrichment, OTel enrichment |
| `manifests/modules/observability/otlp-metrics/.workshop/cleanup.sh` | Added cleanup for OTel enrichment and telemetry enrichment |
| `lab/iam/policies/labs1.yaml` | Added `observabilityadmin:StartTelemetryEnrichment`, `cloudwatch:StartOTelEnrichment` permissions |
