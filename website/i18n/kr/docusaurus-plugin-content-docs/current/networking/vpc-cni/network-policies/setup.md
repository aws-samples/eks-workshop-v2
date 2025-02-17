---
title: "랩 설정"
sidebar_position: 60
---

이 랩에서는 랩 클러스터에 배포된 샘플 애플리케이션에 대한 네트워크 정책을 구현할 것입니다. 샘플 애플리케이션 컴포넌트 아키텍처는 아래와 같습니다.

<img src={require('@site/static/img/sample-app-screens/architecture.webp').default}/>

샘플 애플리케이션의 각 컴포넌트는 자체 네임스페이스에 구현되어 있습니다. 예를 들어, **'ui'** 컴포넌트는 **'ui'** 네임스페이스에 배포되어 있고, **'catalog'** 웹 서비스와 **'catalog'** MySQL 데이터베이스는 **'catalog'** 네임스페이스에 배포되어 있습니다.

현재는 정의된 네트워크 정책이 없어서 샘플 애플리케이션의 모든 컴포넌트가 다른 모든 컴포넌트나 외부 서비스와 통신할 수 있습니다. 예를 들어, 'catalog' 컴포넌트는 'checkout' 컴포넌트와 직접 통신할 수 있습니다. 아래 명령어를 사용하여 이를 확인할 수 있습니다:

```bash
$ kubectl exec deployment/catalog -n catalog -- curl -s http://checkout.checkout/health
{"status":"ok","info":{},"error":{},"details":{}}
```

샘플 애플리케이션의 트래픽 흐름을 더 잘 제어할 수 있도록 몇 가지 네트워크 규칙을 구현하는 것부터 시작해 보겠습니다.