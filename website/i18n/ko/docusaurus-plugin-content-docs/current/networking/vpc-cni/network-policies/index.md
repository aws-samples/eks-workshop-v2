---
title: "Network Policies"
sidebar_position: 10
sidebar_custom_props: { "module": true }
description: "Amazon Elastic Kubernetes Service의 Network Policies를 사용하여 Pod 간의 네트워크 트래픽을 제한합니다."
tmdTranslationSourceHash: '2431e68bee7e383213ec838021213041'
---

::required-time

:::tip 시작하기 전에
이 섹션을 위한 환경을 준비합니다:

```bash wait=30 timeout=600
$ prepare-environment networking/network-policies
```

:::

기본적으로 Kubernetes는 모든 Pod가 제한 없이 자유롭게 서로 통신할 수 있도록 허용합니다. Kubernetes Network Policies를 사용하면 Pod, 네임스페이스 및 IP 블록(CIDR 범위) 간의 트래픽 흐름에 대한 규칙을 정의하고 적용할 수 있습니다. 이들은 가상 방화벽 역할을 하여 Pod 레이블, 네임스페이스, IP 주소 및 포트와 같은 다양한 기준에 따라 ingress(수신) 및 egress(발신) 네트워크 트래픽 규칙을 지정하여 클러스터를 세그먼트화하고 보안을 강화할 수 있습니다.

다음은 몇 가지 주요 요소에 대한 설명과 함께 Network Policy 예시입니다:

::yaml{file="manifests/modules/networking/network-policies/apply-network-policies/example-network-policy.yaml" paths="metadata,spec.podSelector,spec.policyTypes,spec.ingress,spec.egress" title="example-network-policy.yaml"}

1. 다른 Kubernetes 객체와 마찬가지로 `metadata`를 사용하면 주어진 Network Policy의 이름과 네임스페이스를 지정할 수 있습니다
2. `spec.podSelector`는 주어진 Network Policy가 적용될 네임스페이스 내에서 레이블을 기반으로 특정 Pod를 선택할 수 있습니다. 스펙에 빈 Pod selector 또는 matchLabels가 지정되면 정책이 네임스페이스 내의 모든 Pod에 적용됩니다.
3. `spec.policyTypes`는 정책이 선택된 Pod에 대해 ingress 트래픽, egress 트래픽 또는 둘 다에 적용될지 지정합니다. 이 필드를 지정하지 않으면 기본 동작은 Network Policy에 egress 섹션이 있는 경우를 제외하고 ingress 트래픽에만 Network Policy를 적용하는 것이며, 이 경우 Network Policy가 ingress 및 egress 트래픽 모두에 적용됩니다.
4. `ingress`를 사용하면 어떤 Pod(`podSelector`), 네임스페이스(`namespaceSelector`) 또는 CIDR 범위(`ipBlock`)로부터 선택된 Pod로 트래픽이 허용되는지와 어떤 포트 또는 포트 범위를 사용할 수 있는지를 지정하는 ingress 규칙을 구성할 수 있습니다. 포트 또는 포트 범위가 지정되지 않으면 통신에 모든 포트를 사용할 수 있습니다.
5. `egress`를 사용하면 선택된 Pod로부터 어떤 Pod(`podSelector`), 네임스페이스(`namespaceSelector`) 또는 CIDR 범위(`ipBlock`)로 트래픽이 허용되는지와 어떤 포트 또는 포트 범위를 사용할 수 있는지를 지정하는 egress 규칙을 구성할 수 있습니다. 포트 또는 포트 범위가 지정되지 않으면 통신에 모든 포트를 사용할 수 있습니다.

Kubernetes Network Policies에서 허용되거나 제한되는 기능에 대한 자세한 내용은 [Kubernetes 문서](https://kubernetes.io/docs/concepts/services-networking/network-policies/)를 참조하세요.

Network Policies 외에도 IPv4 모드의 Amazon VPC CNI는 "Security Groups for Pods"라는 강력한 기능을 제공합니다. 이 기능을 사용하면 Amazon EC2 Security Groups를 사용하여 노드에 배포된 Pod로 들어오고 나가는 인바운드 및 아웃바운드 네트워크 트래픽을 관리하는 포괄적인 규칙을 정의할 수 있습니다. Security Groups for Pods와 Network Policies 간에 기능의 중복이 있지만 몇 가지 주요 차이점이 있습니다.

- Security Groups는 CIDR 범위로의 ingress 및 egress 트래픽 제어를 허용하는 반면, Network Policies는 Pod, 네임스페이스 및 CIDR 범위로의 ingress 및 egress 트래픽 제어를 허용합니다.
- Security Groups는 다른 Security Groups로부터의 ingress 및 egress 트래픽 제어를 허용하지만, Network Policies에서는 사용할 수 없습니다.

Amazon EKS는 Pod 간의 네트워크 통신을 제한하여 공격 표면을 줄이고 잠재적인 취약점을 최소화하기 위해 Security Groups와 함께 Network Policies를 사용할 것을 강력히 권장합니다.

