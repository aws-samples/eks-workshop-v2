---
title: "Ingress 제어 구현"
sidebar_position: 80
tmdTranslationSourceHash: '5e7b8c2d4eeeec35a7ce285e35982319'
---

<img src={require('@site/static/img/sample-app-screens/architecture.webp').default}/>

아키텍처 다이어그램에서 보듯이, 'catalog' 네임스페이스는 'ui' 네임스페이스로부터만 트래픽을 받으며 다른 네임스페이스로부터는 받지 않습니다. 또한 'catalog' 데이터베이스 컴포넌트는 'catalog' 서비스 컴포넌트로부터만 트래픽을 받을 수 있습니다.

'catalog' 네임스페이스로의 트래픽을 제어하는 ingress 네트워크 정책을 사용하여 위의 네트워크 규칙을 구현할 수 있습니다.

정책을 적용하기 전에는 'catalog' 서비스가 'ui' 컴포넌트로부터 접근 가능합니다:

```bash
$ kubectl exec deployment/ui -n ui -- curl -v catalog.catalog/health --connect-timeout 5
   Trying XXX.XXX.XXX.XXX:80...
* Connected to catalog.catalog (XXX.XXX.XXX.XXX) port 80 (#0)
> GET /health HTTP/1.1
> Host: catalog.catalog
> User-Agent: curl/7.88.1
> Accept: */*
>
< HTTP/1.1 200 OK
...
```

그리고 'orders' 컴포넌트로부터도 접근 가능합니다:

```bash
$ kubectl exec deployment/orders -n orders -- curl -v catalog.catalog/health --connect-timeout 5
   Trying XXX.XXX.XXX.XXX:80...
* Connected to catalog.catalog (XXX.XXX.XXX.XXX) port 80 (#0)
> GET /health HTTP/1.1
> Host: catalog.catalog
> User-Agent: curl/7.88.1
> Accept: */*
>
< HTTP/1.1 200 OK
...
```

이제 'catalog' 서비스 컴포넌트로의 트래픽을 'ui' 컴포넌트로부터만 허용하는 네트워크 정책을 정의하겠습니다:

::yaml{file="manifests/modules/networking/network-policies/apply-network-policies/allow-catalog-ingress-webservice.yaml" paths="spec.podSelector,spec.ingress.0.from.0"}

1. `podSelector`는 레이블이 `app.kubernetes.io/name: catalog`과 `app.kubernetes.io/component: service`인 Pod를 대상으로 합니다
2. 이 `ingress.from` 구성은 `kubernetes.io/metadata.name: ui`로 식별되는 `ui` 네임스페이스에서 실행되고 레이블이 `app.kubernetes.io/name: ui`인 Pod로부터의 인바운드 연결만 허용합니다

정책을 적용해 보겠습니다:

```bash wait=30
$ kubectl apply -f ~/environment/eks-workshop/modules/networking/network-policies/apply-network-policies/allow-catalog-ingress-webservice.yaml
```

이제 'ui'로부터 'catalog' 컴포넌트에 여전히 접근할 수 있는지 확인하여 정책을 검증할 수 있습니다:

```bash
$ kubectl exec deployment/ui -n ui -- curl -v catalog.catalog/health --connect-timeout 5
  Trying XXX.XXX.XXX.XXX:80...
* Connected to catalog.catalog (XXX.XXX.XXX.XXX) port 80 (#0)
> GET /health HTTP/1.1
> Host: catalog.catalog
> User-Agent: curl/7.88.1
> Accept: */*
>
< HTTP/1.1 200 OK
...
```

하지만 'orders' 컴포넌트로부터는 접근할 수 없습니다:

```bash expectError=true
$ kubectl exec deployment/orders -n orders -- curl -v catalog.catalog/health --connect-timeout 5
*   Trying XXX.XXX.XXX.XXX:80...
* ipv4 connect timeout after 4999ms, move on!
* Failed to connect to catalog.catalog port 80 after 5001 ms: Timeout was reached
* Closing connection 0
curl: (28) Failed to connect to catalog.catalog port 80 after 5001 ms: Timeout was reached
...
```

위의 출력에서 볼 수 있듯이 'ui' 컴포넌트만 'catalog' 서비스 컴포넌트와 통신할 수 있으며, 'orders' 서비스 컴포넌트는 통신할 수 없습니다.

하지만 이것은 여전히 'catalog' 데이터베이스 컴포넌트를 열어두고 있으므로, 'catalog' 서비스 컴포넌트만 'catalog' 데이터베이스 컴포넌트와 통신할 수 있도록 네트워크 정책을 구현해 보겠습니다.

::yaml{file="manifests/modules/networking/network-policies/apply-network-policies/allow-catalog-ingress-db.yaml" paths="spec.podSelector,spec.ingress.0.from.0"}

1. `podSelector`는 레이블이 `app.kubernetes.io/name: catalog`과 `app.kubernetes.io/component: mysql`인 Pod를 대상으로 합니다
2. `ingress.from`은 레이블이 `app.kubernetes.io/name: catalog`과 `app.kubernetes.io/component: service`인 Pod로부터의 인바운드 연결만 허용합니다

정책을 적용해 보겠습니다:

```bash wait=30
$ kubectl apply -f ~/environment/eks-workshop/modules/networking/network-policies/apply-network-policies/allow-catalog-ingress-db.yaml
```

'orders' 컴포넌트로부터 'catalog' 데이터베이스에 연결할 수 없음을 확인하여 네트워크 정책을 검증해 보겠습니다:

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

하지만 'catalog' Pod를 재시작하면 여전히 연결할 수 있습니다:

```bash
$ kubectl rollout restart deployment/catalog -n catalog
$ kubectl rollout status deployment/catalog -n catalog --timeout=2m
```

위의 출력에서 볼 수 있듯이 'catalog' 서비스 컴포넌트만 'catalog' 데이터베이스 컴포넌트와 통신할 수 있습니다.

이제 'catalog' 네임스페이스에 대한 효과적인 ingress 정책을 구현했으므로, 샘플 애플리케이션의 다른 네임스페이스와 컴포넌트에도 동일한 논리를 확장하여 샘플 애플리케이션의 공격 표면을 크게 줄이고 네트워크 보안을 강화할 수 있습니다.

