---
title: "Load Balancers"
chapter: true
sidebar_position: 30
sidebar_custom_props: {"module": true}
---

:::tip Before you start
Prepare your environment for this section:

```bash timeout=300 wait=30
$ reset-environment 
```

:::

In this section we'll explore how to expose applications to the outside world using a layer 4 `Service` resource of Type `LoadBalancer` which provisions a Network Load Balancer (NLB).
