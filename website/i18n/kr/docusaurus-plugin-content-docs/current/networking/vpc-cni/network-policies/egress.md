---
title: "송신 제어 구현"
sidebar_position: 70
---

<img src={require('@site/static/img/sample-app-screens/architecture.webp').default}/>

위의 아키텍처 다이어그램에서 보듯이 'ui' 컴포넌트가 프론트엔드 앱입니다. 따라서 'ui' 네임스페이스에서 모든 송신 트래픽을 차단하는 네트워크 정책을 정의하여 'ui' 컴포넌트에 대한 네트워크 제어 구현을 시작할 수 있습니다.

```file
manifests/modules/networking/network-policies/apply-network-policies/default-deny.yaml
```

> **참고** : 네트워크 정책에 네임스페이스가 지정되어 있지 않습니다. 이는 클러스터의 모든 네임스페이스에 잠재적으로 적용될 수 있는 일반적인 정책이기 때문입니다.

```bash wait=30
$ kubectl apply -n ui -f ~/environment/eks-workshop/modules/networking/network-policies/apply-network-policies/default-deny.yaml
```

이제 'ui' 컴포넌트에서 'catalog' 컴포넌트에 접근해 보겠습니다.

```bash expectError=true
$ kubectl exec deployment/ui -n ui -- curl -s http://catalog.catalog/health --connect-timeout 5
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
  0     0    0     0    0     0      0      0 --:--:--  0:00:03 --:--:--     0
curl: (28) Resolving timed out after 5000 milliseconds
command terminated with exit code 28
```

curl 명령을 실행하면 아래와 같은 문구가 출력되어야 하며, 이는 'ui' 컴포넌트가 이제 'catalog' 컴포넌트와 직접 통신할 수 없음을 보여줍니다.

```text
curl: (28) Resolving timed out after 3000 milliseconds
```

위의 정책을 구현하면 'ui' 컴포넌트가 'catalog' 서비스와 다른 서비스 컴포넌트에 접근해야 하므로 샘플 애플리케이션이 더 이상 제대로 작동하지 않게 됩니다. 'ui' 컴포넌트에 대한 효과적인 송신 정책을 정의하려면 컴포넌트의 네트워크 종속성을 이해해야 합니다.

'ui' 컴포넌트의 경우, 'catalog', 'orders' 등과 같은 다른 모든 서비스 컴포넌트와 통신해야 합니다. 이 외에도 'ui'는 클러스터 시스템 네임스페이스의 컴포넌트와도 통신할 수 있어야 합니다. 예를 들어, 'ui' 컴포넌트가 작동하려면 DNS 조회를 수행할 수 있어야 하며, 이를 위해서는 `kube-system` 네임스페이스의 CoreDNS 서비스와 통신해야 합니다.

아래의 네트워크 정책은 위의 요구사항을 고려하여 설계되었습니다. 두 가지 주요 섹션이 있습니다:

- 첫 번째 섹션은 namespaceSelector를 통해 pod 레이블이 "app.kubernetes.io/component: service"와 일치하는 한 모든 네임스페이스에 대한 송신 트래픽을 허용하여, 데이터베이스 컴포넌트에 대한 접근은 제공하지 않으면서 'catalog', 'orders' 등과 같은 모든 서비스 컴포넌트에 대한 송신 트래픽을 허용하는 데 중점을 둡니다.
- 두 번째 섹션은 kube-system 네임스페이스의 모든 컴포넌트에 대한 송신 트래픽을 허용하는 데 중점을 두어, DNS 조회와 시스템 네임스페이스의 컴포넌트와의 기타 주요 통신을 가능하게 합니다.

```file
manifests/modules/networking/network-policies/apply-network-policies/allow-ui-egress.yaml
```

이 추가 정책을 적용해 보겠습니다:

```bash wait=30
$ kubectl apply -f ~/environment/eks-workshop/modules/networking/network-policies/apply-network-policies/allow-ui-egress.yaml
```

이제 'catalog' 서비스에 연결할 수 있는지 테스트해 보겠습니다:

```bash
$ kubectl exec deployment/ui -n ui -- curl http://catalog.catalog/health
OK
```

출력에서 볼 수 있듯이, 이제 'catalog' 서비스에는 연결할 수 있지만 `app.kubernetes.io/component: service` 레이블이 없는 데이터베이스에는 연결할 수 없습니다:

```bash expectError=true
$ kubectl exec deployment/ui -n ui -- curl -v telnet://catalog-mysql.catalog:3306 --connect-timeout 5
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
  0     0    0     0    0     0      0      0 --:--:--  0:00:05 --:--:--     0
* Failed to connect to catalog-mysql.catalog port 3306 after 5000 ms: Timeout was reached
* Closing connection 0
curl: (28) Failed to connect to catalog-mysql.catalog port 3306 after 5000 ms: Timeout was reached
command terminated with exit code 28
```

마찬가지로, 'order' 서비스와 같은 다른 서비스에도 연결할 수 있는지 테스트할 수 있으며, 이는 가능해야 합니다. 하지만 인터넷이나 다른 서드파티 서비스에 대한 호출은 차단되어야 합니다.

```bash expectError=true
$ kubectl exec deployment/ui -n ui -- curl -v www.google.com --connect-timeout 5
   Trying XXX.XXX.XXX.XXX:80...
*   Trying [XXXX:XXXX:XXXX:XXXX::XXXX]:80...
* Immediate connect fail for XXXX:XXXX:XXXX:XXXX::XXXX: Network is unreachable
curl: (28) Failed to connect to www.google.com port 80 after 5001 ms: Timeout was reached
command terminated with exit code 28
```

이제 'ui' 컴포넌트에 대한 효과적인 송신 정책을 정의했으므로, 'catalog' 네임스페이스에 대한 트래픽을 제어하기 위한 네트워크 정책을 구현하기 위해 catalog 서비스와 데이터베이스 컴포넌트에 집중해 보겠습니다.