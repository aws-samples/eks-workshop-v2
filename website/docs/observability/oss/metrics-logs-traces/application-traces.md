---
title: "Application traces"
sidebar_position: 70
---

TODO

![Tempo Traces](./assets/traces-explore.webp)

Once you're satisfied with observing the metrics, logs and traces, you can stop the load generator using the below command.

```bash timeout=180 test=false
$ kubectl delete pod load-generator -n other
```
