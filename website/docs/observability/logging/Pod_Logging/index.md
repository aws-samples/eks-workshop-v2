---
title: "Pod Logging"
sidebar_position: 10
sidebar_custom_props: {"module": true}
---

:::tip Before you start
Prepare your environment for this section:

```bash timeout=300 wait=30
$ reset-environment 
```

:::

In this module we will setup FluentBit agent as a daemonset to stream the pods logs from each node to Amazon CloudWatch logs.

