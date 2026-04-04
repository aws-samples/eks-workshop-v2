---
title: "AWS Inferentia에서 추론 실행"
sidebar_position: 40
tmdTranslationSourceHash: 5c206bfaf5b41e4e71978ecc45f2a279
---

이제 컴파일된 모델을 사용하여 AWS Inferentia 노드에서 추론 워크로드를 실행할 수 있습니다.

### 추론을 위한 Pod 생성

추론을 실행할 이미지를 확인합니다:

```bash
$ echo $AIML_DL_INF_IMAGE
```

이것은 학습에 사용했던 이미지와 다르며 추론에 최적화되어 있습니다.

이제 추론을 위한 Pod를 배포할 수 있습니다. 추론 Pod를 실행하기 위한 매니페스트 파일입니다:

::yaml{file="manifests/modules/aiml/inferentia/inference/inference.yaml" paths="spec.nodeSelector,spec.containers.0.resources.limits"}

1. 추론을 위해 `nodeSelector` 섹션에서 inf2 인스턴스 타입을 지정했습니다.
2. `resources` `limits` 섹션에서 다시 한번 이 Pod를 실행하기 위해 neuron 코어가 필요함을 지정하여 API를 노출합니다.

```bash
$ kubectl kustomize ~/environment/eks-workshop/modules/aiml/inferentia/inference \
  | envsubst | kubectl apply -f-
```

다시 Karpenter는 이번에는 Neuron 코어가 필요한 inf2 인스턴스가 필요한 대기 중인 Pod를 감지합니다. 따라서 Karpenter는 Inferentia 칩이 있는 inf2 인스턴스를 시작합니다. 다음 명령으로 다시 인스턴스 프로비저닝을 모니터링할 수 있습니다:

```bash test=false
$ kubectl logs -l app.kubernetes.io/instance=karpenter -n kube-system -f | jq
...
{
  "level": "INFO",
  "time": "2024-09-19T18:53:34.266Z",
  "logger": "controller",
  "message": "launched nodeclaim",
  "commit": "6e9d95f",
  "controller": "nodeclaim.lifecycle",
  "controllerGroup": "karpenter.sh",
  "controllerKind": "NodeClaim",
  "NodeClaim": {
    "name": "aiml-v64vm"
  },
  "namespace": "",
  "name": "aiml-v64vm",
  "reconcileID": "7b5488c5-957a-4051-a657-44fb456ad99b",
  "provider-id": "aws:///us-west-2b/i-0078339b1c925584d",
  "instance-type": "inf2.xlarge",
  "zone": "us-west-2b",
  "capacity-type": "on-demand",
  "allocatable": {
    "aws.amazon.com/neuron": "1",
    "cpu": "3920m",
    "ephemeral-storage": "89Gi",
    "memory": "14162Mi",
    "pods": "58",
    "vpc.amazonaws.com/pod-eni": "18"
  }
}
...
```

추론 Pod는 Karpenter가 프로비저닝한 노드에 스케줄되어야 합니다. Pod가 준비 상태인지 확인합니다:

:::note
노드를 프로비저닝하고 EKS 클러스터에 추가하며 Pod를 시작하는 데 최대 12분이 걸릴 수 있습니다.
:::

```bash timeout=600
$ kubectl -n aiml wait --for=condition=Ready --timeout=12m pod/inference
```

다음 명령을 사용하여 Pod를 스케줄하기 위해 프로비저닝된 노드에 대한 자세한 정보를 얻을 수 있습니다:

```bash
$ kubectl get node -l karpenter.sh/nodepool=aiml -o jsonpath='{.items[0].status.capacity}' | jq .
```

이 출력은 이 노드가 가진 용량을 보여줍니다:

```json
{
  "aws.amazon.com/neuron": "1",
  "aws.amazon.com/neuroncore": "2",
  "aws.amazon.com/neurondevice": "1",
  "cpu": "4",
  "ephemeral-storage": "104845292Ki",
  "hugepages-1Gi": "0",
  "hugepages-2Mi": "0",
  "memory": "16009632Ki",
  "pods": "58",
  "vpc.amazonaws.com/pod-eni": "18"
}
```

이 노드의 `aws.amazon.com/neuron`이 1인 것을 볼 수 있습니다. Pod가 요청한 Neuron 코어 수만큼 Karpenter가 이 노드를 프로비저닝했습니다.

### 추론 실행

Inferentia에서 Neuron 코어를 사용하여 추론을 실행하는 데 사용할 코드입니다:

```file
manifests/modules/aiml/inferentia/inference/inference.py
```

이 Python 코드는 다음 작업을 수행합니다:

1. 작은 고양이 이미지를 다운로드하고 저장합니다.
2. 이미지를 분류하기 위한 레이블을 가져옵니다.
3. 이 이미지를 가져와서 텐서로 정규화합니다.
4. 이전에 생성한 모델을 로드합니다.
5. 작은 고양이 이미지에 대한 예측을 실행합니다.
6. 예측에서 상위 5개 결과를 가져와서 커맨드 라인에 출력합니다.

이 코드를 Pod에 복사하고, 이전에 업로드한 모델을 다운로드한 다음, 다음 명령을 실행합니다:

```bash
$ kubectl -n aiml cp ~/environment/eks-workshop/modules/aiml/inferentia/inference/inference.py inference:/
$ kubectl -n aiml exec inference -- pip install --upgrade boto3==1.40.16 botocore==1.40.16
$ kubectl -n aiml exec inference -- aws s3 cp s3://$AIML_NEURON_BUCKET_NAME/resnet50_neuron.pt ./
$ kubectl -n aiml exec inference -- python /inference.py

Top 5 labels:
 ['tiger', 'lynx', 'tiger_cat', 'Egyptian_cat', 'tabby']
```

출력으로 상위 5개 레이블을 받습니다. ResNet-50의 사전 학습된 모델을 사용하여 작은 고양이 이미지에 대한 추론을 실행하고 있으므로 이러한 결과가 예상됩니다. 성능을 향상시키기 위한 다음 단계로 우리만의 이미지 데이터 세트를 생성하고 특정 사용 사례에 맞는 모델을 학습할 수 있습니다. 이를 통해 예측 결과를 개선할 수 있습니다.

이것으로 Amazon EKS에서 AWS Inferentia를 사용하는 랩을 마칩니다.

