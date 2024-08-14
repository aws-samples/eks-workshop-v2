---
title: "Simulating Pod Failure"
sidebar_position: 2
description: "Simulate pod failure in your environment using ChaosMesh to test the resiliency of your application."
---

## Overview

TODO:

- fix file visual?
- add more information about this lab and a conclusion
- Note that this experiment is repeatable
- Note that retail store should still work even when the pod fails

In this experiment, you'll simulate a pod failure within your Kubernetes environment to observe how the system responds. The `pod-failure.sh` script will simulate a pod failure using Chaos Mesh. This is the script we will be using:

```file
manifests/modules/resiliency/scripts/pod-failure.sh
```

To make this script executable:

```bash
$ chmod +x $SCRIPT_DIR/pod-failure.sh
```

## Running the Experiment

Run the experiment and monitor the effects on pod distribution:

```bash
$ $SCRIPT_DIR/pod-failure.sh && SECONDS=0; while [ $SECONDS -lt 30 ]; do clear; $SCRIPT_DIR/get-pods-by-az.sh; sleep 1; done
```

This command initiates the pod failure and monitors the pod distribution for 30 seconds to observe how the system handles the failure. You should see one pod dissapear and then reappear.

Check the status of pods in the `ui` namespace:

```bash
$ kubectl get pods -n ui -o wide
```

## Verify Retail Store Availability

To ensure that the retail store is operational, check its availability with the url fetched with this command:

```bash
$ wait-for-lb $(kubectl get ingress -n ui -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}')
```
