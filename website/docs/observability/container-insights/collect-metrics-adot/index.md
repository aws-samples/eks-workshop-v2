---
title: "Enabling Container Insights using Using AWS Distro for OpenTelemetry"
sidebar_position: 60
---

In this tutorial, we will walk through how to enable CloudWatch Container Insights infrastructure metrics with ADOT Collector for an EKS EC2 cluster.

We can deploy the ADOT Collector as a daemon set to the cluster by entering the following command:
```bash
$ kubectl apply -f /workspace/modules/observability/container-insights/adot/config.yaml
``````
Let's inspect the ADOT collector pods collecting Container Insights metrics by running the below command:

```bash 
$ kubectl get pods -n aws-otel-eks
NAME                    READY   STATUS    RESTARTS   AGE
aws-otel-eks-ci-hgbcg   1/1     Running   0          56m
aws-otel-eks-ci-ljwhs   1/1     Running   0          56m
```

If the output of this command includes multiple pods in the Running state as shown above, the collector is running and collecting metrics from the cluster. The collector creates a log group named *aws/containerinsights/**cluster-name**/performance* and sends the metric data as performance log events in EMF format.




