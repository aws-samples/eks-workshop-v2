---
title: "워크로드 재배포"
sidebar_position: 25
---

지금까지 수행한 사용자 지정 네트워킹 업데이트를 테스트하기 위해, 이전 단계에서 프로비저닝한 새 노드에서 실행되도록 `checkout` 배포를 업데이트해 보겠습니다.

변경하기 위해 클러스터의 `checkout` 배포를 수정하는 다음 명령을 실행하세요.

```bash timeout=240
$ kubectl apply -k ~/environment/eks-workshop/modules/networking/custom-networking/sampleapp
$ kubectl rollout status deployment/checkout -n checkout --timeout 180s
```

이 명령은 `checkout` 배포에 `nodeSelector`를 추가합니다.

```kustomization
modules/networking/custom-networking/sampleapp/checkout.yaml
Deployment/checkout
```

"checkout" 네임스페이스에 배포된 마이크로서비스를 검토해 보겠습니다.

```bash
$ kubectl get pods -n checkout -o wide
NAME                              READY   STATUS    RESTARTS   AGE   IP             NODE                                         NOMINATED NODE   READINESS GATES
checkout-5fbbc99bb7-brn2m         1/1     Running   0          98s   100.64.10.16   ip-10-42-10-14.us-west-2.compute.internal    <none>           <none>
checkout-redis-6cfd7d8787-8n99n   1/1     Running   0          49m   10.42.12.33    ip-10-42-12-155.us-west-2.compute.internal   <none>           <none>
```

`checkout` 파드가 VPC에 추가된 `100.64.0.0` CIDR 블록에서 IP 주소를 할당받은 것을 볼 수 있습니다. 아직 재배포되지 않은 파드들은 원래 VPC와 연결된 유일한 CIDR 블록이었던 `10.42.0.0` CIDR 블록에서 주소를 할당받고 있습니다. 이 예시에서 `checkout-redis` 파드는 여전히 이 범위의 주소를 가지고 있습니다.