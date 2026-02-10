---
title: "CloudWatch でのログの確認"
sidebar_position: 40
tmdTranslationSourceHash: "85cb81e77b59ccece01f916ef782d84c"
---

この実習では、各ノードにデプロイされた Fluent Bit エージェントが Amazon CloudWatch Logs に転送した Kubernetes Pod のログを確認する方法を見ていきます。デプロイされたアプリケーションコンポーネントは `stdout` にログを書き込み、これらは各ノードの `/var/log/containers/*.log` パスに保存されます。

まず、Fluent Bit を有効にしてから新しいログが書き込まれることを確認するために、`ui` コンポーネントの Pod をリサイクルしましょう：

```bash
$ kubectl delete pod -n ui --all
$ kubectl rollout status deployment/ui \
  -n ui --timeout 30s
deployment "ui" successfully rolled out
```

その間に、Fluent Bit DaemonSet のログを確認すると、既存のロググループの下に `ui` コンポーネント用の新しいログストリームが作成されていることがわかります。

```bash hook=pods-log
$ kubectl logs daemonset.apps/aws-for-fluent-bit -n kube-system
...
[2025/04/15 12:40:10] [ info] [filter:kubernetes:kubernetes.0]  token updated
[2025/04/15 12:40:10] [ info] [input:tail:tail.0] inotify_fs_add(): inode=16895961 watch_fd=12 name=/var/log/containers/ui-8564fc5cfb-qb7td_ui_ui-4ace14944409ee785708c9031b4c2243bfa065ffe0cd320e219131aa33541a1e.log
[2025/04/15 12:40:11] [ info] [output:cloudwatch_logs:cloudwatch_logs.0] Creating log stream ui-8564fc5cfb-qb7td.ui in log group /aws/eks/fluentbit-cloudwatch/workload/ui
[2025/04/15 12:40:11] [ info] [output:cloudwatch_logs:cloudwatch_logs.0] Created log stream ui-8564fc5cfb-qb7td.ui

```

次に、`kubectl logs` を直接使用して `ui` コンポーネントがログを生成していることを確認できます：

```bash
$ kubectl logs -n ui deployment/ui
Picked up JAVA_TOOL_OPTIONS: -javaagent:/opt/aws-opentelemetry-agent.jar
OpenJDK 64-Bit Server VM warning: Sharing is only supported for boot loader classes because bootstrap classpath has been appended
[otel.javaagent 2023-07-03 23:39:18:499 +0000] [main] INFO io.opentelemetry.javaagent.tooling.VersionLogger - opentelemetry-javaagent - version: 1.24.0-aws

  .   ____          _            __ _ _
 /\\ / ___'_ __ _ _(_)_ __  __ _ \ \ \ \
( ( )\___ | '_ | '_| | '_ \/ _` | \ \ \ \
 \\/  ___)| |_)| | | | | || (_| |  ) ) ) )
  '  |____| .__|_| |_|_| |_\__, | / / / /
 =========|_|==============|___/=/_/_/_/
 :: Spring Boot ::                (v3.0.6)

2023-07-03T23:39:20.472Z  INFO 1 --- [           main] c.a.s.u.UiApplication                    : Starting UiApplication v0.0.1-SNAPSHOT using Java 17.0.7 with PID 1 (/app/app.jar started by appuser in /app)
2023-07-03T23:39:20.488Z  INFO 1 --- [           main] c.a.s.u.UiApplication                    : No active profile set, falling back to 1 default profile: "default"
2023-07-03T23:39:24.985Z  WARN 1 --- [           main] o.s.b.a.e.EndpointId                     : Endpoint ID 'fail-cart' contains invalid characters, please migrate to a valid format.
2023-07-03T23:39:25.132Z  INFO 1 --- [           main] o.s.b.a.e.w.EndpointLinksResolver        : Exposing 15 endpoint(s) beneath base path '/actuator'
2023-07-03T23:39:25.567Z  INFO 1 --- [           main] o.s.b.w.e.n.NettyWebServer               : Netty started on port 8080
2023-07-03T23:39:25.599Z  INFO 1 --- [           main] c.a.s.u.UiApplication                    : Started UiApplication in 5.877 seconds (process running for 7.361)
```

CloudWatch Logs コンソールを開いて、これらのログが表示されていることを確認しましょう：

<ConsoleButton url="https://console.aws.amazon.com/cloudwatch/home?#logsV2:log-groups" service="cloudwatch" label="CloudWatch コンソールを開く"/>

**fluentbit-cloudwatch** でフィルタリングして、Fluent Bit によって作成されたロググループを見つけます：

![CloudWatch Log Group](/docs/observability/logging/pod-logging/log-group.webp)

`/aws/eks/fluentbit-cloudwatch/workload/ui` を選択してログストリームを表示します。各ストリームは個々の Pod に対応しています：

![CloudWatch Log Stream](/docs/observability/logging/pod-logging/log-streams.webp)

ログエントリの1つを展開して、完全な JSON ペイロードを確認できます：

![Pod logs](/docs/observability/logging/pod-logging/logs.webp)
