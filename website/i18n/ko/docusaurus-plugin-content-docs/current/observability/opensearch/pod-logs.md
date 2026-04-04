---
title: "Pod 로깅"
sidebar_position: 30
tmdTranslationSourceHash: '46344f2c19983ecbad56db9c77b46649'
---

이 섹션에서는 Pod 로그를 OpenSearch로 내보내는 방법을 보여줍니다. [AWS for Fluent Bit](https://github.com/aws/aws-for-fluent-bit)을 배포하여 Pod 로그를 OpenSearch로 내보내고, 로그 항목을 생성하며, OpenSearch Pod 로그 대시보드를 살펴봅니다.

다음 네 개의 단락은 Kubernetes의 Pod 로깅과 Fluent Bit 사용에 대한 개요를 제공합니다. 이미 [EKS에서 Pod 로깅](https://www.eksworkshop.com/docs/observability/logging/pod-logging/)에 관한 이전 섹션을 따라하셨다면 이 개요를 건너뛰셔도 됩니다.

현대 애플리케이션 아키텍처의 표준을 제공하는 [Twelve-Factor App 선언](https://12factor.net/)에 따르면, 컨테이너화된 애플리케이션은 [로그를 stdout과 stderr로 출력](https://12factor.net/logs)해야 합니다. 이는 Kubernetes에서도 모범 사례로 간주되며 클러스터 수준 로그 수집 시스템은 이 전제를 기반으로 구축됩니다.

Kubernetes 로깅 아키�eks처는 세 가지 수준을 정의합니다:

- 기본 수준 로깅: kubectl을 사용하여 Pod 로그를 가져오는 기능 (예: `kubectl logs myapp` – 여기서 `myapp`은 클러스터에서 실행 중인 Pod)
- 노드 수준 로깅: 컨테이너 엔진이 애플리케이션의 `stdout`과 `stderr`에서 로그를 캡처하고 로그 파일에 씁니다.
- 클러스터 수준 로깅: 노드 수준 로깅을 기반으로 구축됩니다. 로그 캡처 에이전트가 각 노드에서 실행됩니다. 에이전트는 로컬 파일 시스템의 로그를 수집하여 OpenSearch와 같은 중앙 집중식 로깅 대상으로 보냅니다. 에이전트는 두 가지 유형의 로그를 수집합니다:
  - 노드의 컨테이너 엔진이 캡처한 컨테이너 로그
  - 시스템 로그

Kubernetes는 자체적으로 로그를 수집하고 저장하는 네이티브 솔루션을 제공하지 않습니다. 컨테이너 런타임이 로그를 JSON 형식으로 로컬 파일 시스템에 저장하도록 구성합니다. Docker와 같은 컨테이너 런타임은 컨테이너의 stdout 및 stderr 스트림을 로깅 드라이버로 리디렉션합니다. Kubernetes에서 컨테이너 로그는 노드의 `/var/log/pods/*.log`에 기록됩니다. Kubelet과 컨테이너 런타임은 systemd가 있는 운영 체제의 경우 `/var/logs` 또는 journald에 자체 로그를 씁니다. 그런 다음 Fluentd와 같은 클러스터 전체 로그 수집 시스템이 노드에서 이러한 로그 파일을 tail하고 보관을 위해 로그를 전송할 수 있습니다. 이러한 로그 수집 시스템은 일반적으로 워커 노드에서 DaemonSet으로 실행됩니다.

[Fluent Bit](https://fluentbit.io/)은 다양한 소스에서 데이터와 로그를 수집하고, 필터로 강화하며, CloudWatch, Kinesis Data Firehose, Kinesis Data Streams 및 Amazon OpenSearch Service와 같은 여러 대상으로 전송할 수 있는 경량 로그 프로세서 및 포워더입니다.

다음 다이어그램은 이 섹션의 설정에 대한 개요를 제공합니다. Fluent Bit은 `opensearch-exporter` 네임스페이스에 배포되며 Pod 로그를 OpenSearch 도메인으로 전달하도록 구성됩니다. Pod 로그는 OpenSearch의 `eks-pod-logs` 인덱스에 저장됩니다. 이전에 로드한 OpenSearch 대시보드를 사용하여 Pod 로그를 검사합니다.

![Pod logs to OpenSearch](/docs/observability/opensearch/eks-pod-logs-overview.webp)

Fluent Bit을 [Daemon Set](https://kubernetes.io/docs/concepts/workloads/controllers/daemonset/)으로 배포하고 OpenSearch 도메인으로 Pod 로그를 전송하도록 구성합니다. 기본 구성은 [여기](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/observability/opensearch/config/fluentbit-values.yaml)에서 확인할 수 있습니다. 이전에 가져온 OpenSearch 자격 증명을 사용하여 Fluent Bit을 구성합니다. 마지막 명령은 세 개의 클러스터 노드 각각에서 하나의 Pod로 Fluent Bit이 실행되고 있는지 확인합니다.

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

먼저, Fluent Bit을 활성화한 이후 새로운 로그가 작성되도록 ui 컴포넌트의 Pod를 재시작합니다:

```bash
$ kubectl delete pod -n ui --all
$ kubectl rollout status deployment/ui -n ui --timeout 30s
deployment "ui" successfully rolled out
```

이제 `kubectl logs`를 직접 사용하여 `ui` 컴포넌트가 로그를 생성하는지 확인할 수 있습니다. 로그의 타임스탬프는 현재 시간과 일치해야 합니다(UTC 형식으로 표시됨).

```bash
$ kubectl logs -n ui deployment/ui
Picked up JAVA_TOOL_OPTIONS:

  .   ____          _            __ _ _
 /\\ / ___'_ __ _ _(_)_ __  __ _ \ \ \ \
( ( )\___ | '_ | '_| | '_ \/ _` | \ \ \ \
 \\/  ___)| |_)| | | | | || (_| |  ) ) ) )
  '  |____| .__|_| |_|_| |_\__, | / / / /
 =========|_|==============|___/=/_/_/_/
 :: Spring Boot ::                (v3.4.4)

2025-07-26T10:38:05.763Z  INFO 1 --- [           main] c.a.s.u.UiApplication                    : Starting UiApplication v0.0.1-SNAPSHOT using Java 21.0.7 with PID 1 (/app/app.jar started by appuser in /app)
2025-07-26T10:38:05.820Z  INFO 1 --- [           main] c.a.s.u.UiApplication                    : The following 1 profile is active: "prod"
2025-07-26T10:38:09.105Z  INFO 1 --- [           main] i.o.i.s.a.OpenTelemetryAutoConfiguration : OpenTelemetry Spring Boot starter has been disabled

2025-07-26T10:38:10.323Z  INFO 1 --- [           main] o.s.b.a.e.w.EndpointLinksResolver        : Exposing 4 endpoints beneath base path '/actuator'
2025-07-26T10:38:12.338Z  INFO 1 --- [           main] o.s.b.w.e.n.NettyWebServer               : Netty started on port 8080 (http)
2025-07-26T10:38:12.365Z  INFO 1 --- [           main] c.a.s.u.UiApplication                    : Started UiApplication in 7.481 seconds (process running for 9.223)

```

동일한 로그 항목이 OpenSearch에서도 표시되는지 확인할 수 있습니다. 이전에 본 대시보드 랜딩 페이지에서 Pod 로그 대시보드에 액세스하거나 아래 명령을 사용하여 좌표를 얻으십시오:

```bash
$ printf "\nPod logs dashboard: https://%s/_dashboards/app/dashboards#/view/31a8bd40-790a-11ee-8b75-b9bb31eee1c2 \
        \nUserName: %q \nPassword: %q \n\n" \
        "$OPENSEARCH_HOST" "$OPENSEARCH_USER" "$OPENSEARCH_PASSWORD"

Pod logs dashboard: <OpenSearch Dashboard URL>
Username: <user name>
Password: <password>
```

대시보드 섹션과 필드에 대한 설명은 다음과 같습니다.

1. [헤더] 날짜/시간 범위를 표시합니다. 이 대시보드로 탐색할 시간 범위를 사용자 정의할 수 있습니다 (이 예제에서는 최근 15분)
2. [상단 섹션] `stdout`과 `stderr` 스트림 간의 분할을 보여주는 로그 메시지의 날짜 히스토그램 (모든 네임스페이스 포함)
3. [중간 섹션] 모든 클러스터 네임스페이스에 걸친 분할을 보여주는 로그 메시지의 날짜 히스토그램
4. [하단 섹션] 가장 최근 메시지가 먼저 표시되는 데이터 테이블입니다. 스트림 이름(`stdout` 및 `stderr`)이 Pod 이름과 같은 세부 정보와 함께 표시됩니다. 데모 목적으로 이 섹션은 `ui` 네임스페이스의 로그만 표시하도록 필터링되었습니다
5. [하단 섹션] 개별 Pod에서 수집된 로그 메시지입니다. 이 예제에서 표시된 가장 최근 로그 메시지는 `2023-11-07T02:05:10.616Z  INFO 1 --- [           main] c.a.s.u.UiApplication                    : Started UiApplication in 5.917 seconds (process running for 7.541)`이며, 이는 이전 단계에서 `kubectl logs -n ui deployment/ui`를 실행한 출력의 마지막 줄과 일치합니다

![Pod logging dashboard](/docs/observability/opensearch/pod-logging-dashboard.webp)

로그 항목을 드릴다운하여 전체 JSON 페이로드를 볼 수 있습니다:

1. 각 이벤트 옆의 '>'를 클릭하면 새 섹션이 열립니다
2. 전체 이벤트 문서를 테이블 또는 JSON 형식으로 볼 수 있습니다
3. `log` 속성에는 Pod가 생성한 로그 메시지가 포함됩니다
4. Pod 이름, 네임스페이스 및 Pod 레이블을 포함한 로그 메시지에 대한 메타데이터가 포함됩니다

![Pod logging detail](/docs/observability/opensearch/pod-logging-detail.webp)

