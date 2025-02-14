---
title: "KubeRay와 Neuron 디바이스 설치"
sidebar_position: 10
---

EKS에 노드 풀과 Ray Serve 클러스터를 배포하기 전에, 워크로드가 올바르게 구성될 수 있도록 필요한 도구들을 준비하는 것이 중요합니다.

### Ray 서비스 클러스터를 위한 KubeRay 오퍼레이터 적용

Amazon EKS에서 Ray 클러스터 배포는 [KubeRay 오퍼레이터](https://ray-project.github.io/kuberay/)를 통해 지원되며, 이는 Ray 클러스터를 관리하기 위한 쿠버네티스 네이티브 방식입니다. 모듈로서 KubeRay는 `RayService`, `RayCluster`, `RayJob`이라는 세 가지 고유한 커스텀 리소스 정의를 제공하여 Ray 애플리케이션의 배포를 단순화합니다.

KubeRay 오퍼레이터를 설치하려면 다음 명령어를 적용하세요:

```bash
$ helm repo add kuberay https://ray-project.github.io/kuberay-helm/
"kuberay" has been added to your repositories
```

```bash wait=10
$ helm install kuberay-operator kuberay/kuberay-operator --version 1.1.0
NAME: kuberay-operator
LAST DEPLOYED: Wed Jul 24 14:46:13 2024
NAMESPACE: default
STATUS: deployed
REVISION: 1
TEST-SUITE: None
```

KubeRay가 올바르게 설치되면, 기본 네임스페이스에 존재하는지 확인할 수 있습니다:

```bash
$ kubectl get pods
NAME                                READY   STATUS   RESTARTS   AGE
kuberay-operator-6fcbb94f64-mbfnr   1/1     Running  0          17s
```

### Neuron 디바이스 설치

Karpenter가 Inferentia-2 인스턴스를 적절히 프로비저닝할 수 있도록 [Neuron 디바이스 플러그인 쿠버네티스 매니페스트 파일](https://github.com/aws-neuron/aws-neuron-sdk/tree/master/src/k8)을 EKS 클러스터에 설치해야 합니다.

이를 통해 파드가 `aws.amazon.com/neuron` 리소스 요구사항을 가질 수 있게 되어, 쿠버네티스 스케줄러가 가속화된 머신 러닝 워크로드가 필요한 노드를 프로비저닝할 수 있습니다.

:::tip
이 워크숍에서 제공하는 [AIML 추론 모듈](../../aiml/inferentia/index.md)에서 Neuron 디바이스 플러그인에 대해 더 자세히 알아볼 수 있습니다.
:::

다음 명령어를 사용하여 역할을 배포할 수 있습니다:

```bash
$ kubectl apply -f https://raw.githubusercontent.com/aws-neuron/aws-neuron-sdk/v2.19.1/src/k8/k8s-neuron-device-plugin-rbac.yml
$ kubectl apply -f https://raw.githubusercontent.com/aws-neuron/aws-neuron-sdk/v2.19.1/src/k8/k8s-neuron-device-plugin.yml

serviceaccount/neuron-device-plugin created
clusterrole.rbac.authorization.k8s.io/neuron-device-plugin created
clusterrolebinding.rbac.authorization.k8s.io/neuron-device-plugin created
daemonset.apps/neuron-device-plugin-daemonset created
```

이를 통해 Neuron 코어가 적절히 노출되고 Karpenter에 가속화된 워크로드가 필요한 파드를 프로비저닝할 수 있는 적절한 권한이 부여됩니다.