---
title: "Enabling Container Insights Using AWS Distro for OpenTelemetry"
sidebar_position: 10
---

In this tutorial, we will walk through how to enable CloudWatch Container Insights infrastructure metrics with ADOT Collector for an EKS EC2 cluster.

The first thing we need to do is create resources like a `ServiceAccount`, `ClusterRole` etc. that will be used by the ADOT collector pod to authenticate to both the Kubernetes API as well as CloudWatch to send metrics.

```bash
$ kubectl apply -k /workspace/modules/observability/container-insights/adot
```
Next we'll create the `OpenTelemetryCollector Configmap` object. This needs some extra variables provided from our environment so we'll pass it through `envsubst` before directly applying it.

```bash
$ envsubst < <(cat /workspace/modules/observability/container-insights/adot/configmap.yaml) | kubectl apply -f -
```

Next we'll apply the `Collector Daemonset` to create collector pods in our cluster. 

```bash hook=deploy-adot-ci
$ kubectl apply -f /workspace/modules/observability/container-insights/adot/daemonset.yaml
```

Let's inspect the ADOT collector pods collecting Container Insights metrics by running the below command:

```bash
$ kubectl get pods -n other
NAME                              READY   STATUS    RESTARTS   AGE
aws-otel-eks-ci-6f6b8867f6-lpjb7  1/1     Running   2          11d
```

If the output of this command includes multiple pods in the Running state as shown above, the collector is running and collecting metrics from the cluster. The collector creates a log group named *aws/containerinsights/**cluster-name**/performance* and sends the metric data as performance log events in EMF format.





