---
title: "Pod logging"
sidebar_position: 10
sidebar_custom_props: {"module": true}
---

:::tip Before you start
Prepare your environment for this section:

```bash timeout=300 wait=30
$ reset-environment 
```

:::

According to the [Twelve-Factor App manifesto](https://12factor.net/), which provides the gold standard for architecting modern applications, containerized applications should output their [logs to stdout and stderr](https://12factor.net/logs). This is also considered best practice in Kubernetes and cluster level log collection systems are built on this premise.

The Kubernetes logging architecture defines three distinct levels:

* Basic level logging: the ability to grab pods log using kubectl (e.g. `kubectl logs myapp` – where `myapp` is a pod running in my cluster)
* Node level logging: The container engine captures logs from the application’s `stdout` and `stderr`, and writes them to a log file.
* Cluster level logging: Building upon node level logging; a log capturing agent runs on each node. The agent collects logs on the local filesystem and sends them to a centralized logging destination like Elasticsearch or CloudWatch. The agent collects two types of logs:
  - Container logs captured by the container engine on the node.
  - System logs.

Kubernetes, by itself, doesn’t provide a native solution to collect and store logs. It configures the container runtime to save logs in JSON format on the local filesystem. Container runtime – like Docker – redirects container’s stdout and stderr streams to a logging driver. In Kubernetes, container logs are written to `/var/log/pods/*.log` on the node. Kubelet and container runtime write their own logs to `/var/logs` or to journald, in operating systems with systemd. Then cluster-wide log collector systems like Fluentd can tail these log files on the node and ship logs for retention. These log collector systems usually run as DaemonSets on worker nodes.

In this lab, we'll show how a log agent can be set up to collect logs from nodes in EKS and send them to CloudWatch Logs.
