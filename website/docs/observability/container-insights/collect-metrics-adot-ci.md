---
title: "Enabling Container Insights Using AWS Distro for OpenTelemetry"
sidebar_position: 10
---

In this tutorial, we will walk through how to enable CloudWatch Container Insights infrastructure metrics with ADOT Collector for an EKS EC2 cluster.

The first thing we need to do is create resources like a `ServiceAccount`, `ClusterRole` etc. that will be used by the ADOT collector pod to authenticate to both the Kubernetes API as well as CloudWatch to send metrics.

```bash
$ kubectl apply -k /workspace/modules/observability/container-insights/adot
```

Next we'll create the `OpenTelemetryCollector` object. This needs some extra variables provided from our environment so we'll pass it through `envsubst` before directly applying it.

```bash
$ envsubst < <(cat /workspace/modules/observability/container-insights/adot/opentelemetrycollector.yaml) | kubectl apply -f -
```

Let's inspect the ADOT collector pods collecting Container Insights metrics by running the below command:

```bash
$ kubectl get pods -n other
NAME                               READY   STATUS    RESTARTS   AGE
adot-container-ci-collector-5lp5g  1/1     Running   0          15s
adot-container-ci-collector-ctvgs  1/1     Running   0          15s
```

If the output of this command includes multiple pods in the `Running` state as shown above, the collector is running and collecting metrics from the cluster. The collector creates a log group named *aws/containerinsights/**cluster-name**/performance* and sends the metric data as performance log events in EMF format.





