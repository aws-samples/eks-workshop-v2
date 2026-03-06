---
title: "시나리오 설정"
sidebar_position: 51
tmdTranslationSourceHash: '3ec9b4414036461ebd38ff6e6e06b60c'
---

클러스터의 DNS 해석은 여러 구성 옵션에 의해 영향을 받을 수 있으며, 이는 서비스 통신을 방해할 수 있습니다. 이 모듈에서는 EKS 클러스터에서 자주 발생하는 일반적인 DNS 관련 문제를 시뮬레이션합니다.

### 1단계 - 구성 스크립트 실행

다음 스크립트를 실행하여 이 모듈의 문제를 도입해 보겠습니다:

```bash timeout=180 wait=5
$ bash ~/environment/eks-workshop/modules/troubleshooting/dns/.workshop/lab-setup.sh
Configuration applied successfully!
```

### 2단계 - 애플리케이션 Pod 재시작

다음으로, 애플리케이션 Pod를 재배포합니다:

```bash timeout=30 wait=30
$ kubectl delete pod -l app.kubernetes.io/created-by=eks-workshop -l app.kubernetes.io/component=service -A
```

모든 Pod가 재생성될 때까지 기다린 다음 애플리케이션 상태를 확인합니다. 일부 Pod가 Ready 상태에 도달하지 못하고 Error 또는 CrashLoopBackOff 상태로 여러 번 재시작되는 것을 확인할 수 있습니다:

```bash timeout=30 expectError=true
$ kubectl get pod -l app.kubernetes.io/created-by=eks-workshop -l app.kubernetes.io/component=service -A
NAMESPACE   NAME                              READY   STATUS             RESTARTS      AGE
carts       carts-5475469b7c-gm7kw            0/1     Running            2 (40s ago)   110s
catalog     catalog-5578f9649b-bbrjp          0/1     CrashLoopBackOff   3 (42s ago)   110s
checkout    checkout-84c6769ddd-rvwnv         1/1     Running            0             110s
orders      orders-6d74499d87-lhgwh           0/1     Running            2 (44s ago)   110s
ui          ui-5f4d85f85f-hdhjg               1/1     Running            0             109s
```

### 3단계 - 애플리케이션 문제 트러블슈팅

#### 3.1. 문제 조사

Pod가 제대로 시작되지 않을 때, `kubectl describe pod`를 사용하여 Pod 및 컨테이너 프로비저닝 문제를 확인할 수 있습니다. Ready 상태가 아닌 catalog Pod의 이벤트 섹션을 확인합니다:

```bash timeout=30 expectError=true
$ kubectl describe pod -l app.kubernetes.io/name=catalog -l app.kubernetes.io/component=service -n catalog
...
Events:
  Type     Reason     Age                    From               Message
  ----     ------     ----                   ----               -------
  Normal   Scheduled  3m47s                  default-scheduler  Successfully assigned catalog/catalog-5578f9649b-bbrjp to ip-10-42-100-65.us-west-2.compute.internal
  Normal   Started    3m16s (x3 over 3m46s)  kubelet            Started container catalog
  Warning  Unhealthy  3m12s (x9 over 3m46s)  kubelet            Readiness probe failed: Get "http://10.42.115.209:8080/health": dial tcp 10.42.115.209:8080: connect: connection refused
  Warning  BackOff    2m55s (x5 over 3m34s)  kubelet            Back-off restarting failed container catalog in pod catalog-5578f9649b-bbrjp_catalog(b5c1c1fa-5db6-4be4-8dcd-0910410f5630)
  Normal   Pulled     2m44s (x4 over 3m46s)  kubelet            Container image "public.ecr.aws/aws-containers/retail-store-sample-catalog:0.4.0" already present on machine
  Normal   Created    2m44s (x4 over 3m46s)  kubelet            Created container catalog
```

이벤트를 보면 컨테이너는 시작되지만 애플리케이션이 제대로 실행되지 않습니다. 실패한 readiness 프로브가 컨테이너 재시작을 트리거합니다.

#### 3.1. 애플리케이션 로그 확인

애플리케이션 로그를 확인하여 애플리케이션이 실행되지 않는 이유를 파악합니다:

```bash timeout=30 expectError=true
$ kubectl logs -l app.kubernetes.io/name=catalog -l app.kubernetes.io/component=service -n catalog
2024/10/20 15:19:27 Running database migration...
2024/10/20 15:19:27 Schema migration applied
2024/10/20 15:19:27 Connecting to catalog-mysql:3306/catalog?timeout=5s
2024/10/20 15:19:27 invalid connection config: missing required peer IP or hostname
2024/10/20 15:19:27 Connected
2024/10/20 15:19:27 Connecting to catalog-mysql:3306/catalog?timeout=5s
2024/10/20 15:19:27 invalid connection config: missing required peer IP or hostname
2024/10/20 15:19:32 Error: Unable to connect to reader database dial tcp: lookup catalog-mysql: i/o timeout
2024/10/20 15:19:32 dial tcp: lookup catalog-mysql: i/o timeout
```

로그에서 애플리케이션이 MySQL 데이터베이스 서비스 이름(catalog-mysql)을 해석하려고 할 때 DNS 해석 타임아웃으로 인해 데이터베이스에 연결하지 못하는 것을 알 수 있습니다.

:::info
선택적으로 다른 Ready 상태가 아닌 Pod의 로그를 확인할 수 있으며, 유사한 DNS 해석 실패를 볼 수 있습니다.
:::

### 다음 단계

다음 섹션에서는 DNS 해석 실패의 근본 원인을 파악하기 위한 주요 트러블슈팅 단계를 살펴보겠습니다.

