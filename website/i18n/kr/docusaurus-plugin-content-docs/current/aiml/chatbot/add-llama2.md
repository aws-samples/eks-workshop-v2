---
title: "Ray Serve에 Llama-2-Chat 모델 배포하기"
sidebar_position: 30
---

두 노드 풀이 프로비저닝되었으므로 이제 Llama2 챗봇 인프라를 배포할 수 있습니다.

먼저 `ray-service-llama2.yaml` 파일을 배포하겠습니다:

```bash wait=5
$ kubectl apply -k ~/environment/eks-workshop/modules/aiml/chatbot/ray-service-llama2-chatbot
namespace/llama2 created
rayservice.ray.io/llama2 created
```

### 추론을 위한 Ray Service 파드 생성하기

`ray-service-llama2.yaml` 파일은 Llama2 챗봇을 위한 Ray Serve 서비스를 배포하기 위한 Kubernetes 구성을 정의합니다:

```file
manifests/modules/aiml/chatbot/ray-service-llama2-chatbot/ray-service-llama2.yaml
```

이 구성은 다음과 같은 작업을 수행합니다:

1. 리소스 격리를 위한 `llama2`라는 이름의 Kubernetes 네임스페이스 생성
2. Ray Serve 컴포넌트를 생성하기 위한 Python 스크립트를 사용하는 `llama-2-service`라는 RayService 배포
3. Amazon Elastic Container Registry(ECR)에서 Docker 이미지를 가져오기 위한 Head Pod와 Worker Pod 프로비저닝

구성을 적용한 후, head와 worker 파드의 진행 상황을 모니터링하겠습니다:

```bash wait=5
$ kubectl get pod -n llama2
NAME                                            READY   STATUS    RESTARTS   AGE
pod/llama2-raycluster-fcmtr-head-bf58d          1/1     Running   0          67m
pod/llama2-raycluster-fcmtr-worker-inf2-lgnb2   1/1     Running   0          5m30s
```

:::caution
두 파드가 준비되기까지 최대 15분이 소요될 수 있습니다.
:::

다음 명령을 사용하여 파드가 준비될 때까지 기다릴 수 있습니다:

```bash timeout=900
$ kubectl wait pod \
--all \
--for=condition=Ready \
--namespace=llama2 \
--timeout=15m
pod/llama2-raycluster-fcmtr-head-bf58d met
pod/llama2-raycluster-fcmtr-worker-inf2-lgnb2 met
```

파드가 완전히 배포되면 모든 것이 제대로 설정되었는지 확인합니다:

```bash
$ kubectl get all -n llama2
NAME                                            READY   STATUS    RESTARTS   AGE
pod/llama2-raycluster-fcmtr-head-bf58d          1/1     Running   0          67m
pod/llama2-raycluster-fcmtr-worker-inf2-lgnb2   1/1     Running   0          5m30s

NAME                       TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)                                         AGE
service/llama2             ClusterIP   172.20.118.243   <none>        10001/TCP,8000/TCP,8080/TCP,6379/TCP,8265/TCP   67m
service/llama2-head-svc    ClusterIP   172.20.168.94    <none>        8080/TCP,6379/TCP,8265/TCP,10001/TCP,8000/TCP   57m
service/llama2-serve-svc   ClusterIP   172.20.61.167    <none>        8000/TCP                                        57m

NAME                                        DESIRED WORKERS   AVAILABLE WORKERS   CPUS   MEMORY        GPUS   STATUS   AGE
raycluster.ray.io/llama2-raycluster-fcmtr   1                 1                   184    704565270Ki   0      ready    67m

NAME                       SERVICE STATUS   NUM SERVE ENDPOINTS
rayservice.ray.io/llama2   Running          2
```

:::caution
RayService 구성에는 최대 10분이 소요될 수 있습니다.
:::

다음 명령으로 RayService가 실행될 때까지 기다릴 수 있습니다:

```bash wait=5 timeout=600
$ kubectl wait --for=jsonpath='{.status.serviceStatus}'=Running rayservice/llama2 -n llama2 --timeout=10m
rayservice.ray.io/llama2 condition met
```

모든 것이 제대로 배포되면 이제 챗봇의 웹 인터페이스를 생성할 수 있습니다.