---
title: "Simulating Pod Failure"
sidebar_position: 110
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

### Step 1: Check Initial Pod Status

First, let's check the initial status of the pods in the `ui` namespace:

```bash
$ kubectl get pods -n ui -o wide
```

You should see output similar to this:

```text
NAME                  READY   STATUS    RESTARTS   AGE   IP              NODE                                          NOMINATED NODE   READINESS GATES
ui-6dfb84cf67-44hc9   1/1     Running   0          46s   10.42.121.37    ip-10-42-119-94.us-west-2.compute.internal    <none>           <none>
ui-6dfb84cf67-6d5lq   1/1     Running   0          46s   10.42.121.36    ip-10-42-119-94.us-west-2.compute.internal    <none>           <none>
ui-6dfb84cf67-hqccq   1/1     Running   0          46s   10.42.154.216   ip-10-42-146-130.us-west-2.compute.internal   <none>           <none>
ui-6dfb84cf67-qqltz   1/1     Running   0          46s   10.42.185.149   ip-10-42-176-213.us-west-2.compute.internal   <none>           <none>
ui-6dfb84cf67-rzbvl   1/1     Running   0          46s   10.42.188.96    ip-10-42-176-213.us-west-2.compute.internal   <none>           <none>
```

Note that all pods have similar start times (shown in the AGE column).

### Step 2: Simulate Pod Failure

Now, let's simulate a pod failure:

```bash
$ ~/$SCRIPT_DIR/pod-failure.sh
```

This script will use Chaos Mesh to terminate one of the pods.

### Step 3: Observe Recovery

Wait for a couple of seconds to allow Kubernetes to detect the failure and initiate recovery. Then, check the pod status again:

```bash timeout=5
$ kubectl get pods -n ui -o wide
```

You should now see output similar to this:

```text
NAME                  READY   STATUS    RESTARTS   AGE     IP              NODE                                          NOMINATED NODE   READINESS GATES
ui-6dfb84cf67-44hc9   1/1     Running   0          2m57s   10.42.121.37    ip-10-42-119-94.us-west-2.compute.internal    <none>           <none>
ui-6dfb84cf67-6d5lq   1/1     Running   0          2m57s   10.42.121.36    ip-10-42-119-94.us-west-2.compute.internal    <none>           <none>
ui-6dfb84cf67-ghp5z   1/1     Running   0          6s      10.42.185.150   ip-10-42-176-213.us-west-2.compute.internal   <none>           <none>
ui-6dfb84cf67-hqccq   1/1     Running   0          2m57s   10.42.154.216   ip-10-42-146-130.us-west-2.compute.internal   <none>           <none>
ui-6dfb84cf67-rzbvl   1/1     Running   0          2m57s   10.42.188.96    ip-10-42-176-213.us-west-2.compute.internal   <none>           <none>
[ec2-user@bc44085aafa9 environment]$
```

Notice that one of the pods (in this example, `ui-6dfb84cf67-ghp5z`) has a much lower AGE value. This is the pod that Kubernetes automatically created to replace the one that was terminated by our simulation.

This will show you the status, IP addresses, and nodes for each pod in the `ui` namespace.

## Verify Retail Store Availability

An essential aspect of this experiment is to ensure that your retail store application remains operational throughout the pod failure and recovery process. To verify the availability of the retail store, use the following command to fetch and access the store's URL:

```bash timeout=900
$ wait-for-lb $(kubectl get ingress -n ui -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}')

Waiting for k8s-ui-ui-5ddc3ba496-721427594.us-west-2.elb.amazonaws.com...
You can now access http://k8s-ui-ui-5ddc3ba496-721427594.us-west-2.elb.amazonaws.com
```

Once ready, you can access the retail store through this URL to confirm that it's still functioning correctly despite the simulated pod failure.

## Conclusion

This pod failure simulation demonstrates the resilience of your Kubernetes-based application. By intentionally causing a pod to fail, you can observe:

1. The system's ability to detect failures quickly
2. Kubernetes' automatic rescheduling and recovery of Deployments or StatefulSets failed pods.
3. The application's continued availability during pod failures

Remember that the retail store should remain operational even when a pod fails, showcasing the high availability and fault tolerance of your Kubernetes setup. This experiment helps validate your application's resilience and can be repeated as needed to ensure consistent behavior across different scenarios or after making changes to your infrastructure.

By regularly performing such chaos engineering experiments, you can build confidence in your system's ability to withstand and recover from various types of failures, ultimately leading to a more robust and reliable application.
