---
title: "라우트 구성"
sidebar_position: 30
tmdTranslationSourceHash: '2a099daa7d22fd6797d5afed142a0f8d'
---

이 섹션에서는 Amazon VPC Lattice를 사용하여 블루/그린 및 카나리 스타일 배포를 위한 가중치 기반 라우팅으로 고급 트래픽 관리를 수행하는 방법을 보여드리겠습니다.

배송 옵션에 _"Lattice"_ 접두사가 추가된 수정된 버전의 `checkout` 마이크로서비스를 배포해 보겠습니다. Kustomize를 사용하여 새로운 네임스페이스(`checkoutv2`)에 이 새 버전을 배포하겠습니다.

```bash
$ kubectl apply -k ~/environment/eks-workshop/modules/networking/vpc-lattice/abtesting/
$ kubectl rollout status deployment/checkout -n checkoutv2
```

`checkoutv2` 네임스페이스는 이제 애플리케이션의 두 번째 버전을 포함하며, `checkout` 네임스페이스에 있는 동일한 `redis` 인스턴스를 사용합니다.

```bash
$ kubectl get pods -n checkoutv2
NAME                        READY   STATUS    RESTARTS   AGE
checkout-854cd7cd66-s2blp   1/1     Running   0          26s
```

이제 `HTTPRoute` 리소스를 생성하여 가중치 기반 라우팅이 어떻게 작동하는지 살펴보겠습니다. 먼저 Lattice가 checkout 서비스에 대해 적절한 상태 확인을 수행하는 방법을 알려주는 `TargetGroupPolicy`를 생성하겠습니다:

::yaml{file="manifests/modules/networking/vpc-lattice/target-group-policy/target-group-policy.yaml" paths="spec.targetRef,spec.healthCheck,spec.healthCheck.intervalSeconds,spec.healthCheck.timeoutSeconds,spec.healthCheck.healthyThresholdCount,spec.healthCheck.unhealthyThresholdCount,spec.healthCheck.path,spec.healthCheck.port,spec.healthCheck.protocol,spec.healthCheck.statusMatch"}

1. `targetRef`는 이 정책을 `checkout` Service에 적용합니다
2. `healthCheck` 섹션의 설정은 VPC Lattice가 서비스 상태를 모니터링하는 방법을 정의합니다
3. `intervalSeconds: 10` : 10초마다 확인
4. `timeoutSeconds: 1` : 확인당 1초 타임아웃
5. `healthyThresholdCount: 3` : 연속 3회 성공 = 정상
6. `unhealthyThresholdCount: 2` : 연속 2회 실패 = 비정상
7. `path: "/health"`: 상태 확인 엔드포인트 경로
8. `port: 8080` : 상태 확인 엔드포인트 포트
9. `protocol: HTTP` : 상태 확인 엔드포인트 프로토콜
10. `statusMatch: "200"` : HTTP 200 응답 예상


이 리소스를 적용합니다:

```bash wait=10
$ kubectl apply -k ~/environment/eks-workshop/modules/networking/vpc-lattice/target-group-policy
```

이제 트래픽의 75%를 `checkoutv2`로, 나머지 25%를 `checkout`으로 분산하는 Kubernetes `HTTPRoute` 라우트를 생성합니다:

::yaml{file="manifests/modules/networking/vpc-lattice/routes/checkout-route.yaml" paths="spec.parentRefs.0,spec.rules.0.backendRefs.0,spec.rules.0.backendRefs.1"}

1. `parentRefs`는 이 `HTTPRoute` 라우트를 `${EKS_CLUSTER_NAME}`이라는 이름의 게이트웨이의 `http` 리스너에 연결합니다
2. 이 `backendRefs` 규칙은 트래픽의 `25%`를 `checkout` 네임스페이스의 `checkout` Service 포트 `80`으로 전송합니다
3. 이 `backendRefs` 규칙은 트래픽의 `75%`를 `checkoutv2` 네임스페이스의 `checkout` Service 포트 `80`으로 전송합니다

이 리소스를 적용합니다:

```bash hook=route
$ cat ~/environment/eks-workshop/modules/networking/vpc-lattice/routes/checkout-route.yaml \
  | envsubst | kubectl apply -f -
```

관련 리소스 생성은 2-3분이 소요될 수 있으며, 완료될 때까지 기다리려면 다음 명령을 실행하세요:

```bash wait=10 timeout=400
$ kubectl wait -n checkout --timeout=3m \
  --for=jsonpath='{.metadata.annotations.application-networking\.k8s\.aws\/lattice-assigned-domain-name}' httproute/checkoutroute
```

완료되면 `HTTPRoute` 어노테이션 `application-networking.k8s.aws/lattice-assigned-domain-name`에서 `HTTPRoute`의 DNS 이름을 찾을 수 있습니다:

```bash
$ kubectl describe httproute checkoutroute -n checkout
Name:         checkoutroute
Namespace:    checkout
Labels:       <none>
Annotations:  application-networking.k8s.aws/lattice-assigned-domain-name:
                checkoutroute-checkout-0d8e3f4604a069e36.7d67968.vpc-lattice-svcs.us-east-2.on.aws
API Version:  gateway.networking.k8s.io/v1beta1
Kind:         HTTPRoute
...
```

이제 Lattice 리소스 아래 [VPC Lattice 콘솔](https://console.aws.amazon.com/vpc/home#Services)에서 생성된 관련 Service를 볼 수 있습니다.
![CheckoutRoute Service](/docs/networking/vpc-lattice/checkoutroute.webp)

:::tip 트래픽은 이제 Amazon VPC Lattice에서 처리됩니다
Amazon VPC Lattice는 이제 다른 VPC를 포함한 모든 소스에서 이 서비스로의 트래픽을 자동으로 리디렉션할 수 있습니다! 다른 VPC Lattice [기능](https://aws.amazon.com/vpc/lattice/features/)도 완전히 활용할 수 있습니다.
:::

