---
title: "External DNS"
sidebar_position: 30
tmdTranslationSourceHash: 'b7f399a9ad32bbe99ece1082753fcd42'
---

[ExternalDNS](https://github.com/kubernetes-sigs/external-dns)는 클러스터의 Service와 Ingress에 대한 DNS 레코드를 자동으로 관리하는 Kubernetes 컨트롤러입니다. Kubernetes 리소스와 AWS Route 53과 같은 DNS 제공자 사이의 다리 역할을 하여 DNS 레코드가 클러스터 상태와 동기화되도록 보장합니다. 로드 밸런서에 대한 DNS 항목을 사용하면 자동 생성된 호스트 이름 대신 사람이 읽기 쉽고 기억하기 쉬운 주소를 제공하여 조직의 브랜딩에 맞는 도메인 이름으로 서비스를 쉽게 접근하고 기업 리소스로 인식할 수 있게 합니다.

이 실습에서는 ExternalDNS를 사용하여 AWS Route 53으로 Kubernetes Ingress 리소스에 대한 DNS 관리를 자동화합니다.

먼저 IAM role ARN과 Helm 차트 버전을 환경 변수로 제공하여 Helm을 사용해 ExternalDNS를 설치하겠습니다:

```bash
$ helm repo add external-dns https://kubernetes-sigs.github.io/external-dns/
$ helm upgrade --install external-dns external-dns/external-dns --version "${DNS_CHART_VERSION}" \
    --namespace external-dns \
    --create-namespace \
    --set provider.name=aws \
    --set serviceAccount.create=true \
    --set serviceAccount.name=external-dns-sa \
    --set serviceAccount.annotations."eks\.amazonaws\.com/role-arn"="$DNS_ROLE_ARN" \
    --set txtOwnerId=eks-workshop \
    --set extraArgs[0]=--aws-zone-type=private \
    --set extraArgs[1]=--domain-filter=retailstore.com \
    --wait
```

ExternalDNS Pod가 실행 중인지 확인합니다:

```bash
$ kubectl -n external-dns get pods
NAME                                READY   STATUS    RESTARTS   AGE
external-dns-5bdb4478b-fl48s        1/1     Running   0          2m
```

이제 이전 Ingress 리소스를 DNS 구성으로 업데이트하겠습니다:

::yaml{file="manifests/modules/exposing/ingress/external-dns/ingress.yaml" paths="metadata.annotations,spec.rules.0.host"}

1. `external-dns.alpha.kubernetes.io/hostname` 어노테이션은 ExternalDNS에게 Ingress에 대해 생성하고 관리할 DNS 이름을 알려주며, 앱의 호스트 이름을 로드 밸런서로 매핑하는 것을 자동화합니다.
2. `spec.rules.host`는 Ingress가 수신할 도메인 이름을 정의하며, ExternalDNS는 이를 사용하여 관련된 로드 밸런서에 대한 일치하는 DNS 레코드를 생성합니다.

이 구성을 적용합니다:

```bash
$ kubectl apply -k ~/environment/eks-workshop/modules/exposing/ingress/external-dns
```

호스트 이름과 함께 생성된 Ingress 객체를 확인합니다:

```bash wait=120
$ kubectl get ingress ui   -n ui
NAME     CLASS   HOSTS                    ADDRESS                                            PORTS   AGE
ui       alb     ui.retailstore.com       k8s-ui-ui-1268651632.us-west-2.elb.amazonaws.com   80      4m15s
```

DNS 레코드 생성을 확인하면, ExternalDNS가 `retailstore.com` Route 53 프라이빗 호스팅 영역에 DNS 레코드를 자동으로 생성합니다.

:::note

DNS 항목이 조정되는 데 몇 분 정도 걸릴 수 있습니다.

:::

ExternalDNS 로그를 확인하여 DNS 레코드 생성을 확인합니다:

```bash hook=dns-logs
$ kubectl -n external-dns logs deployment/external-dns
Desired change: CREATE ui.retailstore.com A
5 record(s) were successfully updated
```

링크를 클릭하여 AWS Route 53 콘솔에서 새 DNS 레코드를 확인하고 `retailstore.com` 프라이빗 호스팅 영역으로 이동할 수도 있습니다:

<ConsoleButton url="https://us-east-1.console.aws.amazon.com/route53/v2/hostedzones" service="route53" label="Open Route53 console"/>

Route 53 프라이빗 호스팅 영역은 연결된 VPC에서만 접근할 수 있으며, 이 경우 EKS 클러스터 VPC입니다. DNS 항목을 테스트하기 위해 Pod 내부에서 `curl`을 사용하겠습니다:

```bash hook=dns-curl
$ kubectl -n ui exec -it \
  deployment/ui -- bash -c "curl -i http://ui.retailstore.com/actuator/health/liveness; echo"

HTTP/1.1 200 OK
Date: Thu, 24 Apr 2025 07:45:12 GMT
Content-Type: application/vnd.spring-boot.actuator.v3+json
Content-Length: 15
Connection: keep-alive
Set-Cookie: SESSIONID=c3f13e02-4ff3-40ba-866e-c777f7450997

{"status":"UP"}
```

