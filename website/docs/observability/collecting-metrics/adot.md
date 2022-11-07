---
title: "Scraping metrics using AWS Distro for OpenTelemetry"
sidebar_position: 10
---

To gather the metrics from the Amazon EKS Cluster, we will deploy a `OpenTelemetryCollector` custom resource. The ADOT operator running on the EKS cluster detects the presence of or changes of the this resource and for any such changes, the operator performs the following actions:

- Verifies that all the required connections for these creation, update, or deletion requests to the Kubernetes API server are available.
- Deploys ADOT collector instances in the way the user expressed in the `OpenTelemetryCollector` resource configuration.

The first thing we need to do is create resources like a `ServiceAccount`, `ClusterRole` etc. that will be used by the ADOT collector pod to authenticate to both the Kubernetes API as well as AMP to send metrics.

```bash
$ kubectl apply -k /workspace/modules/observability/oss-metrics/adot
```

Next we'll create the `OpenTelemetryCollector` object. This needs some extra variables provided from our environment so we'll pass it through `envsubst` before directly applying it.

```bash hook=deploy-adot
$ envsubst < <(cat /workspace/modules/observability/oss-metrics/adot/opentelemetrycollector.yaml) | kubectl apply -f -
```

Let's inspect the ADOT collector pod by running the below command:

```bash 
$ kubectl get pods -n other
NAME                              READY   STATUS    RESTARTS   AGE
adot-collector-6f6b8867f6-lpjb7   1/1     Running   2          11d
```