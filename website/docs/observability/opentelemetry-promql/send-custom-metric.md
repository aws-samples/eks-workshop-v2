---
title: "Send Custom Metrics"
sidebar_position: 20
---

Amazon CloudWatch exposes a regional OTLP endpoint (https://monitoring.region.amazonaws.com/v1/metrics) that accepts metrics from any OpenTelemetry-compatible collector. In this section, you configure custom metric collection from both the EKS and ECS environments in the PetAdoptions application.

:::info
The workshop cluster also runs OTel Container Insights, which collects infrastructure metrics (CPU, memory, network per node/pod/container) automatically. For a deep dive into the Container Insights console experience, see the OTel Container Insights (EKS) module.
:::


**Prometheus scraping via CRD**

Deploy the CloudWatch Agent CRD to scrape Prometheus metrics from application workloads:

```bash
export CWA_IMAGE=$(kubectl get daemonset -n amazon-cloudwatch cloudwatch-agent -o jsonpath='{.spec.template.spec.containers[0].image}')
kubectl kustomize ~/environment/eks-workshop/modules/observability/otlp-metrics/otel | envsubst | kubectl apply -f -
```

**Generate Application Load**

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

