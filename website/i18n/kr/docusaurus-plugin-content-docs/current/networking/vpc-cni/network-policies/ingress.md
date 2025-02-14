---
title: "인그레스 제어 구현"
sidebar_position: 80
---

<img src={require('@site/static/img/sample-app-screens/architecture.webp').default}/>

아키텍처 다이어그램에서 보듯이, 'catalog' 네임스페이스는 'ui' 네임스페이스로부터만 트래픽을 받고 다른 네임스페이스로부터는 받지 않습니다. 또한, 'catalog' 데이터베이스 컴포넌트는 'catalog' 서비스 컴포넌트로부터만 트래픽을 받을 수 있습니다.

'catalog' 네임스페이스로의 트래픽을 제어하는 인그레스 네트워크 정책을 사용하여 위의 네트워크 규칙을 구현하기 시작할 수 있습니다.

정책을 적용하기 전에는 'catalog' 서비스에 'ui' 컴포넌트로부터 접근이 가능합니다:

```bash
$ kubectl exec deployment/ui -n ui -- curl -v catalog.catalog/health --connect-timeout 5
   Trying XXX.XXX.XXX.XXX:80...
* Connected to catalog.catalog (XXX.XXX.XXX.XXX) port 80 (#0)
> GET /catalogue HTTP/1.1
> Host: catalog.catalog
> User-Agent: curl/7.88.1
> Accept: */*
>
< HTTP/1.1 200 OK
...
```

그리고 'orders' 컴포넌트로부터도 접근이 가능합니다:

```bash
$ kubectl exec deployment/orders -n orders -- curl -v catalog.catalog/health --connect-timeout 5
   Trying XXX.XXX.XXX.XXX:80...
* Connected to catalog.catalog (XXX.XXX.XXX.XXX) port 80 (#0)
> GET /catalogue HTTP/1.1
> Host: catalog.catalog
> User-Agent: curl/7.88.1
> Accept: */*
>
< HTTP/1.1 200 OK
...
```

이제 'ui' 컴포넌트로부터만 'catalog' 서비스 컴포넌트로의 트래픽을 허용하는 네트워크 정책을 정의하겠습니다:

```file
manifests/modules/networking/network-policies/apply-network-policies/allow-catalog-ingress-webservice.yaml
```

정책을 적용해보겠습니다:

```bash wait=30
$ kubectl apply -f ~/environment/eks-workshop/modules/networking/network-policies/apply-network-policies/allow-catalog-ingress-webservice.yaml
```

이제 'ui'에서 'catalog' 컴포넌트에 여전히 접근할 수 있는지 확인하여 정책을 검증할 수 있습니다:

```bash
$ kubectl exec deployment/ui -n ui -- curl -v catalog.catalog/health --connect-timeout 5
  Trying XXX.XXX.XXX.XXX:80...
* Connected to catalog.catalog (XXX.XXX.XXX.XXX) port 80 (#0)
> GET /catalogue HTTP/1.1
> Host: catalog.catalog
> User-Agent: curl/7.88.1
> Accept: */*
>
< HTTP/1.1 200 OK
...
```

하지만 'orders' 컴포넌트에서는 접근할 수 없습니다:

```bash expectError=true
$ kubectl exec deployment/orders -n orders -- curl -v catalog.catalog/health --connect-timeout 5
*   Trying XXX.XXX.XXX.XXX:80...
* ipv4 connect timeout after 4999ms, move on!
* Failed to connect to catalog.catalog port 80 after 5001 ms: Timeout was reached
* Closing connection 0
curl: (28) Failed to connect to catalog.catalog port 80 after 5001 ms: Timeout was reached
...
```

위의 출력에서 볼 수 있듯이, 'ui' 컴포넌트만이 'catalog' 서비스 컴포넌트와 통신할 수 있고, 'orders' 서비스 컴포넌트는 통신할 수 없습니다.

하지만 이는 여전히 'catalog' 데이터베이스 컴포넌트를 개방된 상태로 두므로, 'catalog' 서비스 컴포넌트만이 'catalog' 데이터베이스 컴포넌트와 통신할 수 있도록 네트워크 정책을 구현해보겠습니다.

```file
manifests/modules/networking/network-policies/apply-network-policies/allow-catalog-ingress-db.yaml
```

정책을 적용해보겠습니다:

```bash wait=30
$ kubectl apply -f ~/environment/eks-workshop/modules/networking/network-policies/apply-network-policies/allow-catalog-ingress-db.yaml
```

'orders' 컴포넌트에서 'catalog' 데이터베이스에 연결할 수 없음을 확인하여 네트워크 정책을 검증해보겠습니다:

```bash expectError=true
$ kubectl exec deployment/orders -n orders -- curl -v telnet://catalog-mysql.catalog:3306 --connect-timeout 5
*   Trying XXX.XXX.XXX.XXX:3306...
* ipv4 connect timeout after 4999ms, move on!
* Failed to connect to catalog-mysql.catalog port 3306 after 5001 ms: Timeout was reached
* Closing connection 0
curl: (28) Failed to connect to catalog-mysql.catalog port 3306 after 5001 ms: Timeout was reached
command terminated with exit code 28
...
```

하지만 'catalog' 파드를 재시작하면 여전히 연결할 수 있습니다:

```bash
$ kubectl rollout restart deployment/catalog -n catalog
$ kubectl rollout status deployment/catalog -n catalog --timeout=2m
```

위의 출력에서 볼 수 있듯이, 'catalog' 서비스 컴포넌트만이 'catalog' 데이터베이스 컴포넌트와 통신할 수 있습니다.

이제 'catalog' 네임스페이스에 대한 효과적인 인그레스 정책을 구현했으므로, 같은 논리를 샘플 애플리케이션의 다른 네임스페이스와 컴포넌트로 확장하여 샘플 애플리케이션의 공격 표면을 크게 줄이고 네트워크 보안을 강화할 수 있습니다.