---
title: "서비스가 엔드포인트를 등록하지 않음"
sidebar_position: 32
tmdTranslationSourceHash: fc331a5ef68d4afb716ae012b9f5dd05
---

이 섹션에서는 Application Load Balancer(ALB)가 Kubernetes 서비스 엔드포인트를 올바르게 등록하지 않는 이유를 해결합니다. ALB가 성공적으로 생성되었음에도 불구하고 백엔드 서비스 구성 문제로 인해 애플리케이션에 접근할 수 없습니다.

### 단계 1: 오류 확인

ALB를 통해 애플리케이션에 접근하면 "Backend service does not exist"라는 오류가 표시됩니다:

![ALb-Backend-DoesNotExist](/docs/troubleshooting/alb/alb-does-not-exist.webp)

Ingress가 성공적으로 생성되었으므로, 이는 Kubernetes Ingress와 서비스 간의 통신 문제를 시사합니다.

### 단계 2: 서비스 구성 검사

서비스 구성을 살펴보겠습니다:

```bash
$ kubectl -n ui get service/ui -o yaml
```

```yaml {12}
apiVersion: v1
kind: Service
metadata:
  annotations: ...
  labels:
    app.kubernetes.io/component: service
    app.kubernetes.io/created-by: eks-workshop
    app.kubernetes.io/instance: ui
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/name: ui
    helm.sh/chart: ui-0.0.1
  name: ui
  namespace: ui
spec:
  ports:
    - name: http
      port: 80
      protocol: TCP
      targetPort: http
  selector:
    app.kubernetes.io/component: service
    app.kubernetes.io/instance: ui
    app.kubernetes.io/name: ui-app
  sessionAffinity: None
  type: ClusterIP
status:
  loadBalancer: {}
```

### 단계 3: Ingress 구성 확인

이제 Ingress 구성을 살펴보겠습니다:

```bash
$ kubectl get ingress/ui -n ui -o yaml
```

```yaml {23}
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  annotations:
    alb.ingress.kubernetes.io/healthcheck-path: /actuator/health/liveness
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    ...
  finalizers:
  - ingress.k8s.aws/resources
  generation: 1
  name: ui
  namespace: ui
  resourceVersion: "4950883"
  uid: 327b899c-405e-431b-8d67-32578435f0b9
spec:
  ingressClassName: alb
  rules:
  - http:
      paths:
      - backend:
          service:
            name: service-ui
            port:
              number: 80
        path: /
        pathType: Prefix
...
```

Ingress가 `service-ui`라는 이름의 서비스를 사용하도록 구성되어 있지만, 실제 서비스 이름은 `ui`입니다.

### 단계 4: Ingress 구성 수정

올바른 서비스 이름을 가리키도록 Ingress를 업데이트하겠습니다:

```bash
$ kubectl apply -k ~/environment/eks-workshop/modules/troubleshooting/alb/creating-alb/fix_ingress
```

수정된 구성은 다음과 같아야 합니다:

```yaml {10}
spec:
  ingressClassName: alb
  rules:
    - http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: ui
                port:
                  number: 80
```

### 단계 5: 서비스 엔드포인트 확인

서비스 이름을 수정한 후에도 503 오류가 표시됩니다:

![ALb-503-ERROR](/docs/troubleshooting/alb/alb-503.webp)

이는 서비스의 백엔드 엔드포인트에 문제가 있음을 시사합니다. 엔드포인트를 확인해 보겠습니다:

```bash
$ kubectl -n ui get endpoints ui
NAME   ENDPOINTS   AGE
ui     <none>     13d
```

비어 있는 엔드포인트는 서비스가 어떤 Pod 백엔드도 올바르게 선택하지 못하고 있음을 나타냅니다.

### 단계 6: 서비스와 Pod 레이블 비교

Deployment의 Pod 레이블을 살펴보겠습니다:

```bash
$ kubectl -n ui get deploy/ui -o yaml
```

```yaml {34}
apiVersion: apps/v1
kind: Deployment
metadata:
  annotations:
    ...
  name: ui
  namespace: ui
  ..
spec:
  progressDeadlineSeconds: 600
  replicas: 1
  revisionHistoryLimit: 10
  selector:
    matchLabels:
      app.kubernetes.io/component: service
      app.kubernetes.io/instance: ui
      app.kubernetes.io/name: ui
  strategy:
    rollingUpdate:
      maxSurge: 25%
      maxUnavailable: 25%
    type: RollingUpdate
  template:
    metadata:
      annotations:
        prometheus.io/path: /actuator/prometheus
        prometheus.io/port: "8080"
        prometheus.io/scrape: "true"
      creationTimestamp: null
      labels:
        app.kubernetes.io/component: service
        app.kubernetes.io/created-by: eks-workshop
        app.kubernetes.io/instance: ui
        app.kubernetes.io/name: ui
    spec:
      containers:
...

```

이것을 서비스 셀렉터와 비교해 보겠습니다:

```bash
$ kubectl -n ui get svc ui -o yaml
```

```yaml {22}
apiVersion: v1
kind: Service
metadata:
  annotations:
    ...
  labels:
    app.kubernetes.io/component: service
    app.kubernetes.io/created-by: eks-workshop
    app.kubernetes.io/instance: ui
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/name: ui
    helm.sh/chart: ui-0.0.1
  name: ui
  namespace: ui
  resourceVersion: "5000404"
  uid: dc832144-b2a1-41cd-b7a1-8979111da677
spec:
  ...
  selector:
    app.kubernetes.io/component: service
    app.kubernetes.io/instance: ui
    app.kubernetes.io/name: ui-app
  sessionAffinity: None
  type: ClusterIP
...
```

서비스 셀렉터 `app.kubernetes.io/name: ui-app`이 Pod 레이블 `app.kubernetes.io/name: ui`와 일치하지 않습니다.

:::tip
다음과 같이 서비스 셀렉터를 업데이트할 수 있습니다:

```text
kubectl edit service <service-name> -n <namespace>
```

또는

```text
kubectl patch service <service-name> -n <namespace> --type='json' -p='[{"op": "replace", "path": "/spec/selector", "value": {"key1": "value1", "key2": "value2"}}]'
```

:::

### 단계 7: 서비스 셀렉터 수정

Pod 레이블과 일치하도록 서비스 셀렉터를 업데이트하겠습니다:

```bash timeout=960 hook=fix-7 hookTimeout=960
$ kubectl apply -k ~/environment/eks-workshop/modules/troubleshooting/alb/creating-alb/fix_ui
```

수정 사항을 적용한 후 브라우저를 새로고침하세요. 이제 UI 애플리케이션이 표시되어야 합니다:

![ALB-UI-APP](/docs/troubleshooting/alb/alb-working.webp)

:::tip
서비스-Pod 연결 문제를 해결할 때:

1. 서비스 셀렉터가 Pod 레이블과 정확히 일치하는지 항상 확인하세요
2. `kubectl get endpoints`를 사용하여 Pod 선택을 확인하세요
3. 레이블 이름과 값의 오타를 확인하세요

:::

서비스 구성 문제를 성공적으로 해결하고 ALB 트러블슈팅 실습을 완료했습니다! 잘 하셨습니다.

