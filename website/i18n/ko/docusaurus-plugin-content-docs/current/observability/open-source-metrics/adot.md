---
title: "AWS Distro for OpenTelemetry를 사용한 메트릭 수집"
sidebar_position: 10
tmdTranslationSourceHash: '6aa970c5e4f2721d7454114bf1c8dcc1'
---

이 실습에서는 메트릭을 Amazon Managed Service for Prometheus 워크스페이스에 저장할 것이며, 이는 이미 생성되어 있습니다. 콘솔에서 확인할 수 있습니다:

<ConsoleButton url="https://console.aws.amazon.com/prometheus/home#/workspaces" service="aps" label="APS 콘솔 열기"/>

워크스페이스를 보려면 왼쪽 제어 패널의 **All Workspaces** 탭을 클릭하세요. **eks-workshop**으로 시작하는 워크스페이스를 선택하면 규칙 관리, 알림 관리자 등과 같은 워크스페이스 아래의 여러 탭을 볼 수 있습니다.

Amazon EKS 클러스터에서 메트릭을 수집하기 위해 `OpenTelemetryCollector` 커스텀 리소스를 배포할 것입니다. EKS 클러스터에서 실행 중인 ADOT 오퍼레이터는 이 리소스의 존재 또는 변경을 감지하고, 이러한 변경 사항에 대해 오퍼레이터는 다음 작업을 수행합니다:

- Kubernetes API 서버에 대한 이러한 생성, 업데이트 또는 삭제 요청에 필요한 모든 연결이 사용 가능한지 확인합니다.
- 사용자가 `OpenTelemetryCollector` 리소스 구성에서 표현한 방식대로 ADOT collector 인스턴스를 배포합니다.

이제 ADOT collector에 필요한 권한을 허용하는 리소스를 생성하겠습니다. collector에 Kubernetes API에 액세스할 수 있는 권한을 부여하는 ClusterRole부터 시작하겠습니다:

::yaml{file="manifests/modules/observability/oss-metrics/adot/clusterrole.yaml" paths="rules.0,rules.1,rules.2"}

1. 이 코어 API 그룹 `""`은 메트릭 수집을 위해 `verbs` 아래에 지정된 작업을 사용하여 `resources` 아래에 나열된 코어 Kubernetes 리소스에 액세스할 수 있는 권한을 역할에 부여합니다
2. 이 확장 API 그룹 `extensions`는 네트워크 트래픽 메트릭 수집을 위해 `verbs` 아래에 지정된 작업을 사용하여 ingress 리소스에 액세스할 수 있는 권한을 역할에 부여합니다
3. `nonResourceURLs`는 클러스터 수준 운영 메트릭 수집을 위해 `verbs` 아래에 지정된 작업을 사용하여 Kubernetes API 서버의 `/metrics` 엔드포인트에 액세스할 수 있는 권한을 역할에 부여합니다

IAM Roles for Service Accounts를 통해 collector에 필요한 IAM 권한을 제공하기 위해 관리형 IAM 정책 `AmazonPrometheusRemoteWriteAccess`를 사용할 것입니다:

```bash
$ aws iam list-attached-role-policies \
  --role-name $EKS_CLUSTER_NAME-adot-collector | jq .
{
  "AttachedPolicies": [
    {
      "PolicyName": "AmazonPrometheusRemoteWriteAccess",
      "PolicyArn": "arn:aws:iam::aws:policy/AmazonPrometheusRemoteWriteAccess"
    }
  ]
}
```

이 IAM 역할은 collector의 ServiceAccount에 추가됩니다:

```file
manifests/modules/observability/oss-metrics/adot/serviceaccount.yaml
```

리소스를 생성합니다:

```bash hook=deploy-adot
$ kubectl kustomize ~/environment/eks-workshop/modules/observability/oss-metrics/adot \
  | envsubst | kubectl apply -f-
$ kubectl rollout status -n other deployment/adot-collector --timeout=120s
```

collector의 사양은 여기에 표시하기에는 너무 길지만, 다음과 같이 볼 수 있습니다:

```bash
$ kubectl -n other get opentelemetrycollector adot -o yaml
```

배포된 내용을 더 잘 이해하기 위해 이를 섹션별로 나누어 보겠습니다. 다음은 OpenTelemetry collector 구성입니다:

```bash
$ kubectl -n other get opentelemetrycollector adot -o jsonpath='{.spec.config}' | jq
```

이는 다음 구조를 가진 OpenTelemetry 파이프라인을 구성합니다:

- Receivers
  - [Prometheus receiver](https://github.com/open-telemetry/opentelemetry-collector-contrib/blob/main/receiver/prometheusreceiver/README.md) Prometheus 엔드포인트를 노출하는 대상에서 메트릭을 수집하도록 설계됨
- Processors
  - 이 파이프라인에는 없음
- Exporters
  - [Prometheus remote write exporter](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/exporter/prometheusremotewriteexporter) AMP와 같은 Prometheus remote write 엔드포인트로 메트릭을 전송

이 collector는 하나의 collector 에이전트가 실행되는 Deployment로 실행되도록 구성되어 있습니다:

```bash
$ kubectl -n other get opentelemetrycollector adot -o jsonpath='{.spec.mode}{"\n"}'
```

실행 중인 ADOT collector Pod를 검사하여 이를 확인할 수 있습니다:

```bash
$ kubectl get pods -n other
NAME                              READY   STATUS    RESTARTS   AGE
adot-collector-6f6b8867f6-lpjb7   1/1     Running   2          11d
```

