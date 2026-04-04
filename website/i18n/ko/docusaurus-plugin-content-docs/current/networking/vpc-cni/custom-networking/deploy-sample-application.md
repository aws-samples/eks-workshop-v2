---
title: "워크로드 재배포"
sidebar_position: 25
tmdTranslationSourceHash: '29da9c8a35ecfcb980663189e5f273c0'
---

지금까지 수행한 커스텀 네트워킹 업데이트를 테스트하기 위해, 이전 단계에서 프로비저닝한 새 노드에서 Pod가 실행되도록 `checkout` Deployment를 업데이트하겠습니다.

변경을 적용하려면 다음 명령을 실행하여 클러스터의 `checkout` Deployment를 수정하세요.

```bash timeout=240
$ kubectl apply -k ~/environment/eks-workshop/modules/networking/custom-networking/sampleapp
$ kubectl rollout status deployment/checkout -n checkout --timeout 180s
```

이 명령은 `checkout` Deployment에 `nodeSelector`를 추가합니다.

```kustomization
modules/networking/custom-networking/sampleapp/checkout.yaml
Deployment/checkout
```

"checkout" 네임스페이스에 배포된 마이크로서비스를 확인해 보겠습니다.

```bash
$ kubectl get pods -n checkout -o wide
NAME                              READY   STATUS    RESTARTS   AGE   IP             NODE                                         NOMINATED NODE   READINESS GATES
checkout-5fbbc99bb7-brn2m         1/1     Running   0          98s   100.64.10.16   ip-10-42-10-14.us-west-2.compute.internal    <none>           <none>
checkout-redis-6cfd7d8787-8n99n   1/1     Running   0          49m   10.42.12.33    ip-10-42-12-155.us-west-2.compute.internal   <none>           <none>
```

`checkout` Pod가 VPC에 추가된 `100.64.0.0` CIDR 블록에서 IP 주소를 할당받은 것을 확인할 수 있습니다. 아직 재배포되지 않은 Pod는 여전히 `10.42.0.0` CIDR 블록에서 주소를 할당받습니다. 이는 원래 VPC와 연결된 유일한 CIDR 블록이었기 때문입니다. 이 예제에서 `checkout-redis` Pod는 여전히 이 범위의 주소를 가지고 있습니다.

