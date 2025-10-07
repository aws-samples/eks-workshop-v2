---
title: "はじめに"
sidebar_position: 10
kiteTranslationSourceHash: 00133c10eccca5df1d8bbb396dac7ac9
---

最初に行うことは、クラスターにKubecostをインストールすることです。ラボの準備の一環として、AWS Load Balancer ControllerとEBS CSIドライバーが事前にインストールされ、Kubecostにイングレスとストレージを提供します。

残りの作業は、HelmチャートとしてKubecostをインストールするだけです：

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

これには数分かかりますが、完了したらKubecostが実行されているかどうかを確認できます：

```bash
$ kubectl get deployment -n kubecost
kubecost-cost-analyzer        1/1     1            1           16m
kubecost-kube-state-metrics   1/1     1            1           16m
kubecost-prometheus-server    1/1     1            1           16m
```

Kubecostは `LoadBalancer` サービスを使用して公開されており、アクセスするURLは次のように見つけることができます：

```bash
$ export KUBECOST_SERVER=$(kubectl get svc -n kubecost kubecost-cost-analyzer -o json | jq --raw-output '.status.loadBalancer.ingress[0].hostname'):9090
$ echo "Kubecost URL: http://$KUBECOST_SERVER"
Kubecost URL: http://k8s-kubecost-kubecost-e83ecf8fc1-fc26f5c92767520f.elb.us-west-2.amazonaws.com:9090
```

ロードバランサーのプロビジョニングには時間がかかるため、Kubecostが応答するまで待つためにこのコマンドを使用します：

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

ブラウザでURLを開いてKubecostにアクセスします：

<Browser url='http://k8s-kubecost-kubecost-e83ecf8fc1-fc26f5c92767520f.elb.us-west-2.amazonaws.com:9090'>
<img src={require('./assets/overview.webp').default}/>
</Browser>

