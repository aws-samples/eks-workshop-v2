---
title: "Pod logging"
sidebar_position: 30
---

This section demonstrates how we can export Kubernetes pod logs to OpenSearch. We'll deploy [AWS for Fluent Bit](https://github.com/aws/aws-for-fluent-bit) to export pod logs to OpenSearch, generate log entries by creating test workloads and explore the OpenSearch pod logs dashboard and use it to identify issues with our test workloads.

Here is a recap of pod logging in Kubernetes and the use of Fluent Bit, which you have already read if you followed the earlier [Logging in EKS](https://www.eksworkshop.com/docs/observability/logging/pod-logging/) section. It describes how pod logging works in Kubernetes:

According to the [Twelve-Factor App manifesto](https://12factor.net/), which provides the gold standard for architecting modern applications, containerized applications should output their [logs to stdout and stderr](https://12factor.net/logs). This is also considered best practice in Kubernetes and cluster level log collection systems are built on this premise.

The Kubernetes logging architecture defines three distinct levels:

* Basic level logging: the ability to grab pods log using kubectl (e.g. `kubectl logs myapp` – where `myapp` is a pod running in my cluster)
* Node level logging: The container engine captures logs from the application’s `stdout` and `stderr`, and writes them to a log file.
* Cluster level logging: Building upon node level logging; a log capturing agent runs on each node. The agent collects logs on the local filesystem and sends them to a centralized logging destination like Elasticsearch or CloudWatch. The agent collects two types of logs:
  * Container logs captured by the container engine on the node
  * System logs

Kubernetes, by itself, doesn’t provide a native solution to collect and store logs. It configures the container runtime to save logs in JSON format on the local filesystem. Container runtime – like Docker – redirects container’s stdout and stderr streams to a logging driver. In Kubernetes, container logs are written to `/var/log/pods/*.log` on the node. Kubelet and container runtime write their own logs to `/var/logs` or to journald, in operating systems with systemd. Then cluster-wide log collector systems like Fluentd can tail these log files on the node and ship logs for retention. These log collector systems usually run as DaemonSets on worker nodes.

[Fluent Bit](https://fluentbit.io/) is a lightweight log processor and forwarder that allows you to collect data and logs from different sources, enrich them with filters and send them to multiple destinations like CloudWatch, Kinesis Data Firehose, Kinesis Data Streams and Amazon OpenSearch Service.

The following diagram provides an overview of the setup for this section. Fluent Bit will be deployed in the `opensearch-exporter` namespace and it will be configured to forward pod logs to the OpenSearch domain. Pod logs are stored in the `eks-pod-logs` index in OpenSearch.  An OpenSearch dashboard that we loaded earlier is used to visualize the events.

![Pod logs to OpenSearch](./assets/eks-pod-logs-overview.svg)

Deploy Fluent Bit as a [Daemon Set](https://kubernetes.io/docs/concepts/workloads/controllers/daemonset/) and configure it to send pod logs to the OpenSearch domain. The base configuration is available [here](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/observability/opensearch/fluentbit). The OpenSearch credentials we retrieved earlier are used to configure Fluent Bit. The last command verifies that Fluent Bit is running with one pod running on each of the three cluster nodes.

```bash wait=60
$ helm repo add eks https://aws.github.io/eks-charts
"eks" has been added to your repositories
 
$ helm upgrade fluentbit eks/aws-for-fluent-bit --install \
    --namespace opensearch-exporter --create-namespace \
    -f ~/environment/eks-workshop/modules/observability/opensearch/config/fluentbit-values.yaml \
    --set="opensearch.host"="$OPENSEARCH_HOST" \
    --set="opensearch.awsRegion"=$AWS_REGION \
    --set="opensearch.httpUser"="$OPENSEARCH_USER" \
    --set="opensearch.httpPasswd"="$OPENSEARCH_PASSWORD" \
    --wait
 
$ kubectl get daemonset -n opensearch-exporter

NAME                           DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR   AGE
fluentbit-aws-for-fluent-bit   3         3         3       3            3           <none>          60s
 
```

Next, we will confirm that the Kubernetes pod logs are being forwarded by the Fluent Bit agent deployed on each node to OpenSearch.  The deployed application components write logs to `stdout`, which are saved in the `/var/log/containers/*.log` path on each node.We will recycle the pods for the `ui` component to make sure fresh logs are written since we enabled Fluent Bit:

```bash
$ kubectl delete pod -n ui --all
$ kubectl rollout status deployment/ui \
  -n ui --timeout 30s
deployment "ui" successfully rolled out
```

Now we can check that our `ui` component is creating logs by directly using `kubectl logs`. The timestamps in the logs should match your current time (shown in UTC Time Format).  

```bash
$ kubectl logs -n ui deployment/ui 
Picked up JAVA_TOOL_OPTIONS: -javaagent:/opt/aws-opentelemetry-agent.jar
OpenJDK 64-Bit Server VM warning: Sharing is only supported for boot loader classes because bootstrap classpath has been appended
[otel.javaagent 2023-11-07 02:05:03:383 +0000] [main] INFO io.opentelemetry.javaagent.tooling.VersionLogger - opentelemetry-javaagent - version: 1.24.0-aws

  .   ____          _            __ _ _
 /\\ / ___'_ __ _ _(_)_ __  __ _ \ \ \ \
( ( )\___ | '_ | '_| | '_ \/ _` | \ \ \ \
 \\/  ___)| |_)| | | | | || (_| |  ) ) ) )
  '  |____| .__|_| |_|_| |_\__, | / / / /
 =========|_|==============|___/=/_/_/_/
 :: Spring Boot ::                (v3.0.6)

2023-11-07T02:05:05.512Z  INFO 1 --- [           main] c.a.s.u.UiApplication                    : Starting UiApplication v0.0.1-SNAPSHOT using Java 17.0.7 with PID 1 (/app/app.jar started by appuser in /app)
2023-11-07T02:05:05.524Z  INFO 1 --- [           main] c.a.s.u.UiApplication                    : No active profile set, falling back to 1 default profile: "default"
2023-11-07T02:05:09.906Z  WARN 1 --- [           main] o.s.b.a.e.EndpointId                     : Endpoint ID 'fail-cart' contains invalid characters, please migrate to a valid format.
2023-11-07T02:05:10.060Z  INFO 1 --- [           main] o.s.b.a.e.w.EndpointLinksResolver        : Exposing 15 endpoint(s) beneath base path '/actuator'
2023-11-07T02:05:10.590Z  INFO 1 --- [           main] o.s.b.w.e.n.NettyWebServer               : Netty started on port 8080
2023-11-07T02:05:10.616Z  INFO 1 --- [           main] c.a.s.u.UiApplication                    : Started UiApplication in 5.917 seconds (process running for 7.541)
 
```

Confirm that the samme log entries are also visible through OpenSearch.  Access the EKS Pod Logs Opensearch Dashboard.





