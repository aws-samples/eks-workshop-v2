---
title: "Introduction"
sidebar_position: 10
---

The first thing we'll do is install Kubecost in our cluster. As part of the lab preparation an the AWS Load Balancer Controller and EBS CSI driver were pre-installed to provide ingress and storage to Kubecost.

All that we have left to do is install Kubecost as a Helm chart:

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

This will take a few minutes to complete, then we can check to see if Kubecost is running:

```bash
$ kubectl get deployment -n kubecost
kubecost-cost-analyzer        1/1     1            1           16m
kubecost-kube-state-metrics   1/1     1            1           16m
kubecost-prometheus-server    1/1     1            1           16m
```

Kubecost has been exposed using a `LoadBalancer` service, and we can find the URL to access it like so:

```bash
$ export KUBECOST_SERVER=$(kubectl get svc -n kubecost kubecost-cost-analyzer -o json | jq --raw-output '.status.loadBalancer.ingress[0].hostname'):9090
$ echo "Kubecost URL: http://$KUBECOST_SERVER"
Kubecost URL: http://k8s-kubecost-kubecost-e83ecf8fc1-fc26f5c92767520f.elb.us-west-2.amazonaws.com:9090
```

The load balancer will take some time to provision so use this command to wait until Kubecost responds:

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

Open the URL in your browser to access Kubecost:

<Browser url='http://k8s-kubecost-kubecost-e83ecf8fc1-fc26f5c92767520f.elb.us-west-2.amazonaws.com:9090'>
<img src={require('@site/static/docs/observability/kubecost/overview.webp').default}/>
</Browser>
