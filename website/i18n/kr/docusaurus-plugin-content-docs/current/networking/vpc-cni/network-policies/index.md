---
title: "네트워크 정책"
sidebar_position: 10
sidebar_custom_props: { "module": true }
description: "네트워크 정책을 통해 Amazon Elastic Kubernetes Service(EKS)의 파드 간 네트워크 트래픽을 제한합니다."
---

::required-time

:::tip 시작하기 전에
이 섹션을 위해 환경을 준비하세요:

```bash wait=30 timeout=600
$ prepare-environment networking/network-policies
```

:::

기본적으로 Kubernetes는 모든 파드가 제한 없이 자유롭게 서로 통신할 수 있도록 허용합니다. Kubernetes 네트워크 정책을 사용하면 파드, 네임스페이스 및 IP 블록(CIDR 범위) 간의 트래픽 흐름에 대한 규칙을 정의하고 적용할 수 있습니다. 이는 가상 방화벽처럼 작동하여 파드 레이블, 네임스페이스, IP 주소 및 포트와 같은 다양한 기준에 따라 수신(들어오는) 및 송신(나가는) 네트워크 트래픽 규칙을 지정하여 클러스터를 분할하고 보호할 수 있게 합니다.

다음은 네트워크 정책의 예시입니다.

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: test-network-policy
  namespace: default
spec:
  podSelector:
    matchLabels:
      role: db
  policyTypes:
    - Ingress
    - Egress
  ingress:
    - from:
        - ipBlock:
            cidr: 172.17.0.0/16
            except:
              - 172.17.1.0/24
        - namespaceSelector:
            matchLabels:
              project: myproject
        - podSelector:
            matchLabels:
              role: frontend
      ports:
        - protocol: TCP
          port: 6379
  egress:
    - to:
        - ipBlock:
            cidr: 10.0.0.0/24
      ports:
        - protocol: TCP
          port: 5978
```

네트워크 정책 명세에는 다음과 같은 주요 부분이 포함됩니다:

- **metadata**: 다른 Kubernetes 객체와 유사하게, 주어진 네트워크 정책의 이름과 네임스페이스를 지정할 수 있습니다.
- **spec.podSelector**: 주어진 네트워크 정책이 적용될 네임스페이스 내에서 레이블을 기반으로 특정 파드를 선택할 수 있습니다. 빈 파드 선택기나 matchLabels가 명세에 지정된 경우, 해당 정책은 네임스페이스 내의 모든 파드에 적용됩니다.
- **spec.policyTypes**: 선택된 파드에 대해 정책이 수신 트래픽, 송신 트래픽 또는 둘 다에 적용될지 지정합니다. 이 필드를 지정하지 않으면, 기본 동작은 네트워크 정책을 수신 트래픽에만 적용하는 것입니다. 단, 네트워크 정책에 송신 섹션이 있는 경우에는 수신과 송신 트래픽 모두에 적용됩니다.
- **ingress**: 어떤 파드(podSelector), 네임스페이스(namespaceSelector) 또는 CIDR 범위(ipBlock)로부터의 트래픽이 선택된 파드로 허용되는지, 그리고 어떤 포트 또는 포트 범위를 사용할 수 있는지 지정하는 수신 규칙을 구성할 수 있습니다. 포트 또는 포트 범위가 지정되지 않은 경우, 통신에 모든 포트를 사용할 수 있습니다.

Kubernetes 네트워크 정책에서 허용되거나 제한되는 기능에 대한 자세한 내용은 [Kubernetes 문서](https://kubernetes.io/docs/concepts/services-networking/network-policies/)를 참조하세요.

네트워크 정책 외에도, IPv4 모드의 Amazon VPC CNI는 "파드용 보안 그룹"이라는 강력한 기능을 제공합니다. 이 기능을 사용하면 Amazon EC2 보안 그룹을 사용하여 노드에 배포된 파드로의 인바운드 및 아웃바운드 네트워크 트래픽을 제어하는 포괄적인 규칙을 정의할 수 있습니다. 파드용 보안 그룹과 네트워크 정책 간에 기능이 중복되는 부분이 있지만, 몇 가지 주요 차이점이 있습니다.

- 보안 그룹은 CIDR 범위에 대한 수신 및 송신 트래픽을 제어할 수 있는 반면, 네트워크 정책은 파드, 네임스페이스 및 CIDR 범위에 대한 수신 및 송신 트래픽을 제어할 수 있습니다.
- 보안 그룹은 다른 보안 그룹으로부터의 수신 및 송신 트래픽을 제어할 수 있지만, 네트워크 정책에서는 이 기능을 사용할 수 없습니다.

Amazon EKS는 파드 간 네트워크 통신을 제한하여 공격 표면을 줄이고 잠재적 취약점을 최소화하기 위해 보안 그룹과 함께 네트워크 정책을 사용할 것을 강력히 권장합니다.