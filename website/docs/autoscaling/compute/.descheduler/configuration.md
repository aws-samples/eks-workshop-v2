---
title: "Configuration"
sidebar_position: 2
---

Before we begin let's reset our environment:

```bash timeout=300 wait=30
$ reset-environment 
```

The descheduler component can be installed as a `Job`, `CronJob`, `Deployment` in a cluster. In this workshop, descheduler is installed as a `Deployment` object with 1 minute interval.

A policy has been pre-configured in the environment, which you can see:

```bash
$ kubectl describe cm descheduler -n kube-system
```

TODO: Explain what they're seeing
