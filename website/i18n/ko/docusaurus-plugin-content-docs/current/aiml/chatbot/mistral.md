---
title: "모델 서빙하기"
sidebar_position: 40
tmdTranslationSourceHash: '8be737eefe98f295a58cdb1a8ad5c77b'
---

[vLLM](https://github.com/vllm-project/vllm)은 효율적인 메모리 관리를 통해 대규모 언어 모델(LLM)의 성능을 최적화하도록 특별히 설계된 오픈 소스 추론 및 서빙 엔진입니다. ML 커뮤니티에서 인기 있는 추론 솔루션인 vLLM은 다음과 같은 주요 장점을 제공합니다:

- **효율적인 메모리 관리**: PagedAttention 기술을 사용하여 GPU/가속기 메모리 사용을 최적화합니다
- **높은 처리량**: 여러 요청의 동시 처리를 가능하게 합니다
- **AWS Neuron 지원**: AWS Inferentia 및 Trainium 가속기와의 기본 통합을 제공합니다
- **OpenAI 호환 API**: OpenAI의 API를 대체할 수 있어 통합이 간단합니다

특히 AWS Neuron의 경우 vLLM은 다음을 제공합니다:

- Neuron SDK 및 런타임에 대한 기본 지원
- Inferentia/Trainium 아키텍처에 최적화된 메모리 관리
- 효율적인 스케일링을 위한 지속적인 모델 로딩
- AWS Neuron 프로파일링 도구와의 통합

이 실습에서는 `neuronx-distributed-inference` 프레임워크로 컴파일된 [Mistral-7B-v0.3 모델](https://mistral.ai/news/announcing-mistral-7b)을 사용할 것입니다. 이 모델은 기능과 리소스 요구 사항 간의 균형을 잘 제공하여 Neuron 기반 EKS 클러스터에 배포하기에 적합합니다.

모델을 배포하기 위해 vLLM 기반 컨테이너 이미지를 사용하여 모델과 가중치를 로드하는 표준 Kubernetes Deployment를 사용할 것입니다:

::yaml{file="manifests/modules/aiml/chatbot/vllm.yaml"}

필요한 리소스를 생성해 보겠습니다:

```bash
$ kubectl create namespace vllm
$ kubectl apply -f ~/environment/eks-workshop/modules/aiml/chatbot/vllm.yaml
```

생성된 리소스를 확인할 수 있습니다:

```bash
$ kubectl get deployment -n vllm
NAME      READY   UP-TO-DATE   AVAILABLE   AGE
mistral   0/1     1            0           33s
$ kubectl get service -n vllm
NAME      TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
mistral   ClusterIP   172.16.149.89   <none>        8080/TCP   33m
```

모델 초기화 프로세스는 완료하는 데 몇 분이 걸립니다. vLLM Pod는 다음 단계를 거칩니다:

1. Karpenter가 Neuron 인스턴스를 프로비저닝할 때까지 Pending 상태로 유지됩니다
2. init 컨테이너를 사용하여 Hugging Face에서 호스트 파일 시스템 경로로 모델을 다운로드합니다
3. vLLM 컨테이너 이미지(약 10GB)를 다운로드합니다
4. vLLM 서비스를 시작합니다
5. 파일 시스템에서 모델을 로드합니다
6. 포트 8080의 HTTP 엔드포인트를 통해 모델 서빙을 시작합니다

이러한 단계를 거치는 동안 Pod의 상태를 모니터링하거나 모델이 로드되는 동안 다음 섹션으로 진행할 수 있습니다.

기다리기로 선택한 경우 Pod가 Init 상태로 전환되는 것을 지켜볼 수 있습니다(종료하려면 Ctrl + C를 누르세요):

```bash test=false
$ kubectl get pod -n vllm --watch
NAME                       READY   STATUS    RESTARTS   AGE
mistral-6889d675c5-2l6x2   0/1     Pending   0          21s
mistral-6889d675c5-2l6x2   0/1     Pending   0          29s
mistral-6889d675c5-2l6x2   0/1     Pending   0          29s
mistral-6889d675c5-2l6x2   0/1     Pending   0          30s
mistral-6889d675c5-2l6x2   0/1     Pending   0          38s
mistral-6889d675c5-2l6x2   0/1     Pending   0          50s
mistral-6889d675c5-2l6x2   0/1     Init:0/1   0          50s
# Exit once the Pod reaches the Init state
```

모델을 다운로드하는 init 컨테이너의 로그를 확인할 수 있습니다(종료하려면 Ctrl + C를 누르세요):

```bash test=false
$ kubectl logs deployment/mistral -n vllm -c model-download -f
[...]
Downloading 'weights/tp0_sharded_checkpoint.safetensors' to '/models/mistral-7b-v0.3/.cache/huggingface/download/weights/dAuF3Bw92r-GdZ-yzT84Iweq-RQ=.6794a3d7f2b1d071399a899a42bcd5652e83ebdd140f02f562d90b292ae750aa.incomplete'
Download complete. Moving file to /models/mistral-7b-v0.3/weights/tp0_sharded_checkpoint.safetensors
Downloading 'weights/tp1_sharded_checkpoint.safetensors' to '/models/mistral-7b-v0.3/.cache/huggingface/download/weights/eEdQSCIfRYQ2putRDwZhjh7Te8E=.14c5bd3b07c4f4b752a65ee99fe9c79ae0110c7e61df0d83ef4993c1ee63a749.incomplete'
Download complete. Moving file to /models/mistral-7b-v0.3/weights/tp1_sharded_checkpoint.safetensors

Model download is complete.
# Exit once the logs reach this point
```

init 컨테이너가 완료되면 시작되는 vLLM 컨테이너 로그를 모니터링할 수 있습니다(종료하려면 Ctrl + C를 누르세요):

```bash test=false
$ kubectl logs deployment/mistral -n vllm -c vllm -f
[...]
INFO 09-30 04:43:37 [launcher.py:36] Route: /v2/rerank, Methods: POST
INFO 09-30 04:43:37 [launcher.py:36] Route: /invocations, Methods: POST
INFO 09-30 04:43:37 [launcher.py:36] Route: /metrics, Methods: GET
INFO:     Started server process [7]
INFO:     Waiting for application startup.
INFO:     Application startup complete.
INFO:     10.42.114.242:38674 - "GET /health HTTP/1.1" 200 OK
INFO:     10.42.114.242:50134 - "GET /health HTTP/1.1" 200 OK
# Exit once the logs reach this point
```

이러한 단계를 완료했거나 모델이 초기화되는 동안 다음으로 진행하기로 결정한 후에는 다음 작업으로 진행할 수 있습니다.

