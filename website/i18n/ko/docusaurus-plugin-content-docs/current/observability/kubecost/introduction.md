---
title: "소개"
sidebar_position: 10
tmdTranslationSourceHash: 'ae393634b2df08c97fb378b53a9b884c'
---

가장 먼저 할 일은 클러스터에 Kubecost를 설치하는 것입니다. 랩 준비 과정의 일환으로 AWS Load Balancer Controller와 EBS CSI 드라이버가 사전 설치되어 Kubecost에 인그레스와 스토리지를 제공합니다.

이제 남은 것은 Helm 차트로 Kubecost를 설치하는 것뿐입니다:

```bash timeout=300
$ aws ecr-public get-login-password \
  --region us-east-1 | helm registry login \
  --username AWS \
  --password-stdin public.ecr.aws
$ helm upgrade --install kubecost oci://public.ecr.aws/kubecost/cost-analyzer \
  --version "${KUBECOST_CHART_VERSION}" \
  --namespace "kubecost" --create-namespace \
  --values https://raw.githubusercontent.com/kubecost/cost-analyzer-helm-chart/v${KUBECOST_CHART_VERSION}/cost-analyzer/values-eks-cost-monitoring.yaml \
  --values ~/environment/eks-workshop/modules/observability/kubecost/values.yaml \
  --wait
NAME: kubecost
LAST DEPLOYED: Thu Jun 13 17:48:55 2024
NAMESPACE: kubecost
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
[...]
```

완료하는 데 몇 분이 걸립니다. 그런 다음 Kubecost가 실행 중인지 확인할 수 있습니다:

```bash
$ kubectl get deployment -n kubecost
kubecost-cost-analyzer        1/1     1            1           16m
kubecost-kube-state-metrics   1/1     1            1           16m
kubecost-prometheus-server    1/1     1            1           16m
```

Kubecost는 `LoadBalancer` 서비스를 사용하여 노출되었으며, 다음과 같이 액세스할 URL을 찾을 수 있습니다:

```bash
$ export KUBECOST_SERVER=$(kubectl get svc -n kubecost kubecost-cost-analyzer -o json | jq --raw-output '.status.loadBalancer.ingress[0].hostname'):9090
$ echo "Kubecost URL: http://$KUBECOST_SERVER"
Kubecost URL: http://k8s-kubecost-kubecost-e83ecf8fc1-fc26f5c92767520f.elb.us-west-2.amazonaws.com:9090
```

로드 밸런서가 프로비저닝되는 데 시간이 걸리므로 다음 명령을 사용하여 Kubecost가 응답할 때까지 기다립니다:

```bash timeout=300
$ curl --head -X GET --retry 20 --retry-all-errors --retry-delay 15 \
  --connect-timeout 5 --max-time 10 \
  http://$KUBECOST_SERVER
curl: (6) Could not resolve host: k8s-kubecost-kubecost-e83ecf8fc1-fc26f5c92767520f.elb.us-west-2.amazonaws.com
Warning: Problem : timeout. Will retry in 15 seconds. 20 retries left.
[...]
HTTP/1.1 200 OK
Server: nginx/1.24.0
Date: Thu, 13 Jun 2024 17:53:16 GMT
Content-Type: text/html
Content-Length: 1150
Last-Modified: Thu, 12 Oct 2023 17:01:29 GMT
Connection: keep-alive
ETag: 1.106.3
Cache-Control: must-revalidate
Cache-Control: max-age=300
Accept-Ranges: bytes
```

브라우저에서 URL을 열어 Kubecost에 액세스합니다:

<Browser url='http://k8s-kubecost-kubecost-e83ecf8fc1-fc26f5c92767520f.elb.us-west-2.amazonaws.com:9090'>
<img src={require('@site/static/docs/observability/kubecost/overview.webp').default}/>
</Browser>

