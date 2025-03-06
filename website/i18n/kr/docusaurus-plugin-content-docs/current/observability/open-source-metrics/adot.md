---
title: "AWS Distro for OpenTelemetry를 사용한 메트릭 스크래핑"
sidebar_position: 10
---

이 실습에서는 이미 생성된 Amazon Managed Service for Prometheus 작업 공간에 메트릭을 저장할 것입니다. 콘솔에서 확인할 수 있어야 합니다:

<ConsoleButton url="https://console.aws.amazon.com/prometheus/home#/workspaces" service="aps" label="APS 콘솔 열기"/>

작업 공간을 보려면 왼쪽 제어 패널에서 **모든 작업 공간** 탭을 클릭하세요. **eks-workshop**으로 시작하는 작업 공간을 선택하면 규칙 관리, 알림 관리자 등 작업 공간 아래의 여러 탭을 볼 수 있습니다.

Amazon EKS 클러스터에서 메트릭을 수집하기 위해 `OpenTelemetryCollector` 사용자 정의 리소스를 배포할 것입니다. EKS 클러스터에서 실행 중인 ADOT 운영자는 이 리소스의 존재나 변경을 감지하고, 그러한 변경에 대해 다음 작업을 수행합니다:

- 이러한 생성, 업데이트 또는 삭제 요청에 대해 Kubernetes API 서버에 필요한 모든 연결이 가능한지 확인합니다.
- `OpenTelemetryCollector` 리소스 구성에서 사용자가 표현한 방식으로 ADOT 수집기 인스턴스를 배포합니다.

이제 ADOT 수집기에 필요한 권한을 부여하는 리소스를 생성해 보겠습니다. 먼저 수집기에 Kubernetes API 접근 권한을 부여하는 ClusterRole부터 시작하겠습니다:

```file
manifests/modules/observability/oss-metrics/adot/clusterrole.yaml
```

IAM 역할을 서비스 계정에 사용하여 수집기에 필요한 IAM 권한을 제공하기 위해 관리형 IAM 정책 `AmazonPrometheusRemoteWriteAccess`를 사용할 것입니다:

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

이 IAM 역할은 수집기의 ServiceAccount에 추가될 것입니다:

```file
manifests/modules/observability/oss-metrics/adot/serviceaccount.yaml
```

리소스를 생성합니다:

```bash hook=deploy-adot
$ kubectl kustomize ~/environment/eks-workshop/modules/observability/oss-metrics/adot \
  | envsubst | kubectl apply -f-
$ kubectl rollout status -n other deployment/adot-collector --timeout=120s
```

수집기의 사양은 여기에 표시하기에는 너무 길지만, 다음과 같이 볼 수 있습니다:

```bash
$ kubectl -n other get opentelemetrycollector adot -o yaml
```

이를 더 잘 이해하기 위해 섹션별로 나누어 살펴보겠습니다. 이것은 OpenTelemetry 수집기 구성입니다:

```bash
$ kubectl -n other get opentelemetrycollector adot -o jsonpath='{.spec.config}' | yq
```

이는 다음과 같은 구조로 OpenTelemetry 파이프라인을 구성하고 있습니다:

- 수신기
  - Prometheus 엔드포인트를 노출하는 대상에서 메트릭을 스크래핑하도록 설계된 [Prometheus 수신기](https://github.com/open-telemetry/opentelemetry-collector-contrib/blob/main/receiver/prometheusreceiver/README.md)
- 프로세서
  - 이 파이프라인에는 없음
- 내보내기
  - AMP와 같은 Prometheus 원격 쓰기 엔드포인트로 메트릭을 보내는 [Prometheus 원격 쓰기 내보내기](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/exporter/prometheusremotewriteexporter)

이 수집기는 또한 하나의 수집기 에이전트가 실행되는 Deployment로 구성되어 있습니다:

```bash
$ kubectl -n other get opentelemetrycollector adot -o jsonpath='{.spec.mode}{"\n"}'
```

실행 중인 ADOT 수집기 Pod를 검사하여 이를 확인할 수 있습니다:

```bash
$ kubectl get pods -n other
NAME                              READY   STATUS    RESTARTS   AGE
adot-collector-6f6b8867f6-lpjb7   1/1     Running   2          11d
```