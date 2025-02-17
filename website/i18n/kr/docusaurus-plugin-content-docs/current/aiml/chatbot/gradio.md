---
title: "Gradio 웹 사용자 인터페이스 접근 구성"
sidebar_position: 40
---

Ray Serve 클러스터 내에서 모든 리소스가 구성되면 이제 Llama2 챗봇에 직접 접근할 차례입니다. 웹 인터페이스는 Gradio UI로 구동됩니다.

:::tip
이 워크샵에서 제공하는 [로드 밸런서 모듈](../../fundamentals/exposing/loadbalancer/index.md)에서 로드 밸런서에 대해 더 자세히 알아볼 수 있습니다.
:::

### Gradio 웹 사용자 인터페이스 배포하기

AWS Load Balancer 컨트롤러가 설치되면 Gradio UI 컴포넌트를 배포할 수 있습니다.

```file
manifests/modules/aiml/chatbot/gradio/gradio-ui.yaml
```

컴포넌트는 애플리케이션을 실행하기 위한 `Deployment`, `Service`, `ConfigMap`으로 구성됩니다. 특히 `Service` 컴포넌트는 gradio-service라는 이름으로 `LoadBalancer`로 배포됩니다.

```bash
$ kubectl apply -k ~/environment/eks-workshop/modules/aiml/chatbot/gradio
namespace/gradio-llama2-inf2 created
configmap/gradio-app-script created
service/gradio-service created
deployment.apps/gradio-deployment created
```

각 컴포넌트의 상태를 확인하려면 다음 명령어를 실행하세요:

```bash
$ kubectl get deployments -n gradio-llama2-inf2
NAME                READY   UP-TO-DATE   AVAILABLE   AGE
gradio-deployment   1/1     1            1           95s
```

```bash
$ kubectl get configmaps -n gradio-llama2-inf2
NAME                DATA   AGE
gradio-app-script   1      110s
kube-root-ca.crt    1      111s
```

### 챗봇 웹사이트 접근하기

로드 밸런서 배포가 완료되면 외부 IP 주소를 사용하여 웹사이트에 직접 접근할 수 있습니다:

```bash wait=10
$ kubectl get services -n gradio-llama2-inf2
NAME             TYPE          ClUSTER-IP    EXTERNAL-IP                                                                      PORT(S)         AGE
gradio-service   LoadBalancer  172.20.84.26  k8s-gradioll-gradiose-a6d0b586ce-06885d584b38b400.elb.us-west-2.amazonaws.com    80:30802/TCP    8m42s
```

Network Load Balancer(NLB)의 프로비저닝이 완료될 때까지 기다리려면 다음 명령어를 실행하세요:

```bash wait=240 timeout=600
$ curl --head -X GET --retry 30 --retry-all-errors --retry-delay 15 --connect-timeout 5 --max-time 10 \
-k $(kubectl get service -n gradio-llama2-inf2 gradio-service -o jsonpath="{.status.loadBalancer.ingress[*].hostname}{'\n'}")
```

이제 우리의 애플리케이션이 외부 세계에 노출되었으니, 웹 브라우저에 URL을 붙여넣어 접근해 보겠습니다. Llama2 챗봇을 보게 될 것이며 질문을 통해 상호작용할 수 있습니다.

<Browser url="http://k8s-gradioll-gradiose-a6d0b586ce-06885d584b38b400.elb.us-west-2.amazonaws.com">
<img src={require('@site/static/img/sample-app-screens/chatbot.webp').default}/>
</Browser>

이것으로 Karpenter를 통해 EKS 클러스터 내에 Meta Llama-2-13b 챗봇 모델을 배포하는 현재 실습을 마칩니다.