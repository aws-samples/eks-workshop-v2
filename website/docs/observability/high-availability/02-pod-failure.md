---
title: "Simulating Pod Failure"
sidebar_position: 3
description: "Simulate pod failure in your environment using ChaosMesh to test the resiliency of your application."
---

## Overview

In this lab, you'll simulate a pod failure within your Kubernetes environment to observe how the system responds and recovers. This experiment is designed to test the resiliency of your application under adverse conditions, specifically when a pod unexpectedly fails.

The `pod-failure.sh` script utilizes Chaos Mesh, a powerful chaos engineering platform for Kubernetes, to simulate a pod failure. This controlled experiment allows you to:

1. Observe the system's immediate response to pod failure
2. Monitor the automatic recovery process
3. Verify that your application remains available despite the simulated failure

This experiment is repeatable, allowing you to run it multiple times to ensure consistent behavior and to test various scenarios or configurations. This is the script we will be using:

```file
manifests/modules/observability/resiliency/scripts/pod-failure.sh
```

## Running the Experiment

To simulate the pod failure and monitor its effects, run the following command:

```bash timeout=90 wait=30
$ $SCRIPT_DIR/pod-failure.sh && SECONDS=0; while [ $SECONDS -lt 30 ]; do clear; $SCRIPT_DIR/get-pods-by-az.sh; sleep 1; done
------us-west-2a------
  ip-10-42-127-82.us-west-2.compute.internal:
       ui-6dfb84cf67-dsp55   1/1   Running   0     2m10s
       ui-6dfb84cf67-gzd9s   1/1   Running   0     8s

------us-west-2b------
  ip-10-42-153-179.us-west-2.compute.internal:
       ui-6dfb84cf67-2pxnp   1/1   Running   0     2m13s

------us-west-2c------
  ip-10-42-186-246.us-west-2.compute.internal:
       ui-6dfb84cf67-n8x4f   1/1   Running   0     2m17s
       ui-6dfb84cf67-wljth   1/1   Running   0     2m17s
```

This command does the following:

1. Initiates the pod failure simulation using the `pod-failure.sh` script
2. Monitors the pod distribution across Availability Zones (AZs) for 30 seconds
3. Updates the display every second to show real-time changes

During the experiment, you should observe one pod disappearing and then reappearing, demonstrating the system's ability to detect and recover from failures.

To get a more detailed view of the pods in the `ui` namespace, use the following command:

```bash wait=15
$ kubectl get pods -n ui -o wide
NAME                  READY   STATUS    RESTARTS   AGE     IP              NODE                                          NOMINATED NODE   READINESS GATES
ui-6dfb84cf67-2pxnp   1/1     Running   0          2m56s   10.42.154.151   ip-10-42-153-179.us-west-2.compute.internal   <none>           <none>
ui-6dfb84cf67-dsp55   1/1     Running   0          2m56s   10.42.126.161   ip-10-42-127-82.us-west-2.compute.internal    <none>           <none>
ui-6dfb84cf67-gzd9s   1/1     Running   0          71s     10.42.126.246   ip-10-42-127-82.us-west-2.compute.internal    <none>           <none>
ui-6dfb84cf67-n8x4f   1/1     Running   0          2m56s   10.42.190.250   ip-10-42-186-246.us-west-2.compute.internal   <none>           <none>
ui-6dfb84cf67-wljth   1/1     Running   0          2m56s   10.42.190.249   ip-10-42-186-246.us-west-2.compute.internal   <none>           <none>
```

This will show you the status, IP addresses, and nodes for each pod in the `ui` namespace.

## Verify Retail Store Availability

An essential aspect of this experiment is to ensure that your retail store application remains operational throughout the pod failure and recovery process. To verify the availability of the retail store, use the following command to fetch and access the store's URL:

```bash timeout=600 wait=30
$ wait-for-lb $(kubectl get ingress -n ui -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}')
Waiting for k8s-ui-ui-5ddc3ba496-721427594.us-west-2.elb.amazonaws.com...
You can now access http://k8s-ui-ui-5ddc3ba496-721427594.us-west-2.elb.amazonaws.com
```

Once ready, you can access the retail store through this URL to confirm that it's still functioning correctly despite the simulated pod failure.

## Conclusion

This pod failure simulation demonstrates the resilience of your Kubernetes-based application. By intentionally causing a pod to fail, you can observe:

1. The system's ability to detect failures quickly
2. Kubernetes' automatic rescheduling and recovery of failed pods
3. The application's continued availability during pod failures

Remember that the retail store should remain operational even when a pod fails, showcasing the high availability and fault tolerance of your Kubernetes setup. This experiment helps validate your application's resilience and can be repeated as needed to ensure consistent behavior across different scenarios or after making changes to your infrastructure.

By regularly performing such chaos engineering experiments, you can build confidence in your system's ability to withstand and recover from various types of failures, ultimately leading to a more robust and reliable application.
