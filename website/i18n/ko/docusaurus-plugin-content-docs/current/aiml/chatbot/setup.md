---
title: "Neuron 플러그인 설치"
sidebar_position: 20
tmdTranslationSourceHash: '1899107d1121abd3081665e847b56da9'
---

Kubernetes가 AWS Neuron 가속기를 인식하고 효과적으로 활용하려면 Neuron 디바이스 플러그인을 설치해야 합니다. 이 플러그인은 Neuron 코어와 디바이스를 Kubernetes 클러스터 내에서 스케줄 가능한 리소스로 노출하는 역할을 담당하며, 워크로드가 요청할 때 스케줄러가 Neuron 가속이 있는 노드를 적절하게 프로비저닝할 수 있도록 합니다.

[AWS Neuron SDK](https://awsdocs-neuron.readthedocs-hosted.com/en/latest/)는 AWS Inferentia 및 Trainium 칩에서 머신 러닝 워크로드를 활성화하는 소프트웨어 개발 키트입니다. 디바이스 플러그인은 Kubernetes의 리소스 관리 기능과 이러한 특수 가속기를 연결하는 핵심 구성 요소입니다.

공식 [Neuron 디바이스 플러그인 Helm 차트](https://gallery.ecr.aws/neuron/neuron-helm-chart)를 사용하여 Neuron 디바이스 플러그인을 설치해 보겠습니다:

```bash
$ helm upgrade --install neuron-helm-chart oci://public.ecr.aws/neuron/neuron-helm-chart \
  --namespace kube-system --version 1.5.0 \
  --values ~/environment/eks-workshop/modules/aiml/chatbot/neuron-values.yaml \
  --wait
```

DaemonSet이 성공적으로 생성되었는지 확인할 수 있습니다:

```bash
$ kubectl get ds neuron-device-plugin -n kube-system
NAME                   DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR   AGE
neuron-device-plugin   0         0         0       0            0           <none>          10s
```

아직 클러스터에 Neuron 디바이스를 제공하는 컴퓨팅 노드가 없기 때문에 현재 실행 중인 Pod가 없습니다. 다음 섹션에서 Neuron 인스턴스를 프로비저닝하면 DaemonSet이 자동으로 해당 노드에 디바이스 플러그인을 배포하여 워크로드에서 Neuron 디바이스를 사용할 수 있게 됩니다.

