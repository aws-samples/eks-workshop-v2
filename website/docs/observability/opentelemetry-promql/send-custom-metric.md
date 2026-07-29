---
title: "Send Custom Metrics"
sidebar_position: 20
---

Amazon CloudWatch exposes a regional OTLP endpoint (https://monitoring.region.amazonaws.com/v1/metrics) that accepts metrics from any OpenTelemetry-compatible collector. In this section, you configure custom metric collection from both the EKS and ECS environments in the PetAdoptions application.

:::info
The workshop cluster also runs OTel Container Insights, which collects infrastructure metrics (CPU, memory, network per node/pod/container) automatically. For a deep dive into the Container Insights console experience, see the OTel Container Insights (EKS) module.
:::


**Two paths, one destination**


**Petsite on EKS (Prometheus scraping via CRD)**

The petsite service exposes Prometheus metrics at :8080/metrics. Verify the endpoint:

```bash hook=cluster-logging
$ kubectl run curl-test --image=curlimages/curl --rm -it --restart=Never -n petsite -- curl -s http://service-petsite.petsite.svc.cluster.local:8080/metrics | head -20
```
You should see metrics like dotnet_gc_heap_size_bytes, petsite_petsearches_total, petsite_pets_waiting_for_adoption, etc.

**Deploy the collector**

The CloudWatch Observability add-on includes an operator that manages AmazonCloudWatchAgent custom resources. Create a YAML file for a standalone collector:

```bash hook=cluster-logging
$ REGION=${AWS_REGION:-${AWS_DEFAULT_REGION:-$(aws configure get region)}}
$ CWA_IMAGE=$(kubectl get daemonset -n amazon-cloudwatch cloudwatch-agent -o jsonpath='{.spec.template.spec.containers[0].image}')

$ cat > /tmp/petsite-collector.yaml << EOF
apiVersion: cloudwatch.aws.amazon.com/v1alpha1
kind: AmazonCloudWatchAgent
metadata:
  name: petsite-metrics-collector
  namespace: amazon-cloudwatch
spec:
  mode: deployment
  replicas: 1
  image: ${CWA_IMAGE}
  serviceAccount: cloudwatch-agent
  config: '{"agent":{"region":"${REGION}"}}'
  otelConfig: |
    exporters:
      otlphttp/cw:
        auth:
          authenticator: sigv4auth/cw
        endpoint: https://monitoring.${REGION}.amazonaws.com:443
        tls:
          insecure: false
    extensions:
      sigv4auth/cw:
        region: ${REGION}
        service: monitoring
    processors:
      batch:
        send_batch_max_size: 500
        send_batch_size: 500
        timeout: 10s
    receivers:
      prometheus:
        config:
          scrape_configs:
            - job_name: petsite-dotnet
              scrape_interval: 60s
              static_configs:
                - targets: ['service-petsite.petsite.svc.cluster.local:8080']
    service:
      extensions: [sigv4auth/cw]
      pipelines:
        metrics/petsite:
          exporters: [otlphttp/cw]
          processors: [batch]
          receivers: [prometheus]
EOF

$ echo "File created. Review:"
$ cat /tmp/petsite-collector.yaml

```
Apply it:

```bash hook=cluster-logging
$ kubectl get pods -n amazon-cloudwatch -l app.kubernetes.io/name=petsite-metrics-collector

```

Verify the pod is running:

```bash hook=cluster-logging
$ kubectl apply -f /tmp/petsite-collector.yaml
```
Check the logs:

```bash hook=cluster-logging
$ kubectl logs -n amazon-cloudwatch -l app.kubernetes.io/name=petsite-metrics-collector --tail=5
```

