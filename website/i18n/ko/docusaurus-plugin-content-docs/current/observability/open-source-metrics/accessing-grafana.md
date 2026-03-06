---
title: "Grafana 접속"
sidebar_position: 30
tmdTranslationSourceHash: '1c39985a7c86ef01590c8c217d5278e3'
---

Grafana 인스턴스가 여러분의 EKS 클러스터에 사전 설치되어 있습니다. 접속하려면 먼저 URL을 확인해야 합니다:

```bash hook=check-grafana
$ kubectl get ingress -n grafana grafana -o=jsonpath='{.status.loadBalancer.ingress[0].hostname}{"\n"}'
k8s-grafana-grafana-123497e39be-2107151316.us-west-2.elb.amazonaws.com
```

브라우저에서 이 URL을 열면 로그인 화면이 나타납니다.

![Grafana 대시보드](/docs/observability/open-source-metrics/grafana-login.webp)

사용자의 자격 증명을 확인하려면 Grafana helm 차트에서 생성된 secret을 조회하세요:

```bash
$ kubectl get -n grafana secrets/grafana -o=jsonpath='{.data.admin-user}' | base64 -d; printf "\n"
$ kubectl get -n grafana secrets/grafana -o=jsonpath='{.data.admin-password}' | base64 -d; printf "\n"
```

Grafana 콘솔에 로그인한 후 datasources 섹션을 살펴보겠습니다. Amazon Managed Service for Prometheus 워크스페이스가 이미 데이터 소스로 구성되어 있는 것을 확인할 수 있습니다.

![Amazon Managed Service for Prometheus 데이터 소스](/docs/observability/open-source-metrics/datasource.webp)

