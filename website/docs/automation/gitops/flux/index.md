---
title: "Flux"
sidebar_position: 2
sidebar_custom_props: {"module": true}
---

:::tip Before you start
Prepare your environment for this section:

```bash timeout=300 wait=30
$ reset-environment 
```

:::

Flux keeps Kubernetes clusters in sync with configuration kept under source control like Git repositories, and automates updates to that configuration when there is new code to deploy. It's built using Kubernetes’ API extension server, and can integrate with Prometheus and other core components of the Kubernetes ecosystem. Flux supports multi-tenancy and syncs an arbitrary number of Git repositories.
