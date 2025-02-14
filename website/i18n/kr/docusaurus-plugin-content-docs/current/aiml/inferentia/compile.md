---
title: "AWS Trainium으로 사전 학습된 모델 컴파일하기"
sidebar_position: 30
---

AWS Inferentia를 활용하고자 하는 모델은 AWS Neuron SDK를 사용하여 AWS Inferentia용으로 컴파일되어야 합니다.

다음은 Inferentia 사용을 위해 모델을 컴파일하는 코드입니다:

```file
manifests/modules/aiml/inferentia/compiler/trace.py
```

이 코드는 사전 학습된 ResNet-50 모델을 로드하고 평가 모드로 설정합니다. 모델에 추가적인 학습 데이터를 추가하지 않는다는 점에 유의하세요. 그런 다음 AWS Neuron SDK를 사용하여 모델을 저장합니다.

EKS 클러스터에 Pod를 배포하고 AWS Inferentia 사용을 위한 샘플 모델을 컴파일할 것입니다. AWS Inferentia용 모델 컴파일에는 [AWS Neuron SDK](https://aws.amazon.com/machine-learning/neuron/)가 필요합니다. 이 SDK는 AWS에서 제공하는 [Deep Learning Containers (DLCs)](https://github.com/aws/deep-learning-containers/blob/v8.12-tf-1.15.5-tr-gpu-py37/available_images.md#neuron-inference-containers)에 포함되어 있습니다.

### 디바이스 플러그인 설치

DLC가 Neuron 코어를 사용하기 위해서는 이들이 노출되어야 합니다. [Neuron 디바이스 플러그인 Kubernetes 매니페스트 파일](https://github.com/aws-neuron/aws-neuron-sdk/tree/master/src/k8)은 Neuron 코어를 DLC에 노출시킵니다. 이러한 매니페스트 파일들은 EKS 클러스터에 미리 설치되어 있습니다.

Pod가 노출된 Neuron 코어를 필요로 할 때, Kubernetes 스케줄러는 Pod를 스케줄링하기 위한 Inferentia 또는 Trainium 노드를 프로비저닝할 수 있습니다.

실행할 이미지를 확인하세요:

```bash
$ echo $AIML_DL_TRN_IMAGE
```

### 학습을 위한 Pod 생성

EKS에서 Pod로 이 코드를 실행할 것입니다. 다음은 Pod 실행을 위한 매니페스트 파일입니다:

::yaml{file="manifests/modules/aiml/inferentia/compiler/compiler.yaml" paths="spec.nodeSelector,spec.containers.0.resources.limits"}

1. `nodeSelector` 섹션에서 이 pod를 실행할 인스턴스 유형을 지정합니다. 이 경우에는 trn1 인스턴스입니다.
2. `resources` `limits` 섹션에서 이 Pod를 실행하는 데 필요한 neuron 코어를 지정합니다. 이는 Neuron 디바이스 플러그인에게 neuron API를 Pod에 노출하도록 지시합니다.

다음 명령을 실행하여 Pod를 생성하세요:

```bash timeout=900
$ kubectl kustomize ~/environment/eks-workshop/modules/aiml/inferentia/compiler \
  | envsubst | kubectl apply -f-
```

Karpenter는 trn1 인스턴스와 Neuron 코어가 필요한 대기 중인 Pod를 감지하고 요구사항을 충족하는 trn1 인스턴스를 시작합니다. 다음 명령으로 인스턴스 프로비저닝을 모니터링하세요:

```bash test=false
$ kubectl logs -l app.kubernetes.io/instance=karpenter -n kube-system -f | jq
{
  "level": "INFO",
  "time": "2024-09-19T18:44:08.919Z",
  "logger": "controller",
  "message": "launched nodeclaim",
  "commit": "6e9d95f",
  "controller": "nodeclaim.lifecycle",
  "controllerGroup": "karpenter.sh",
  "controllerKind": "NodeClaim",
  "NodeClaim": {
    "name": "aiml-hp9wm"
  },
  "namespace": "",
  "name": "aiml-hp9wm",
  "reconcileID": "b38f0b3c-f146-4544-8ddc-ca73574c97f0",
  "provider-id": "aws:///us-west-2b/i-06bc9a7cb6f92887c",
  "instance-type": "trn1.2xlarge",
  "zone": "us-west-2b",
  "capacity-type": "on-demand",
  "allocatable": {
    "aws.amazon.com/neuron": "1",
    "cpu": "7910m",
    "ephemeral-storage": "89Gi",
    "memory": "29317Mi",
    "pods": "58",
    "vpc.amazonaws.com/pod-eni": "17"
  }
}
```

Pod는 Karpenter가 프로비저닝한 노드에 스케줄링되어야 합니다. Pod가 준비 상태인지 확인하세요:

```bash timeout=600
$ kubectl -n aiml wait --for=condition=Ready --timeout=10m pod/compiler
```

:::warning
이 명령은 최대 10분이 소요될 수 있습니다.
:::

다음으로, 모델 컴파일을 위한 코드를 Pod에 복사하고 실행하세요:

```bash timeout=240
$ kubectl -n aiml cp ~/environment/eks-workshop/modules/aiml/inferentia/compiler/trace.py compiler:/
$ kubectl -n aiml exec compiler -- python /trace.py

....
Downloading: "https://download.pytorch.org/models/resnet50-0676ba61.pth" to /root/.cache/torch/hub/checkpoints/resnet50-0676ba61.pth
100%|-------| 97.8M/97.8M [00:00<00:00, 165MB/s]
.
Compiler status PASS
```

마지막으로, 모델을 여러분을 위해 생성된 S3 버킷에 업로드하세요. 이를 통해 나중에 실습에서 모델을 사용할 수 있습니다.

```bash
$ kubectl -n aiml exec compiler -- aws s3 cp ./resnet50_neuron.pt s3://$AIML_NEURON_BUCKET_NAME/

upload: ./resnet50_neuron.pt to s3://eksworkshop-inference20230511204343601500000001/resnet50_neuron.pt
```