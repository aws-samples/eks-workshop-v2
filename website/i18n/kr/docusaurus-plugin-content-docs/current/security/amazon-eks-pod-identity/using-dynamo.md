---
title: "Amazon DynamoDB 사용하기"
sidebar_position: 32
---

이 과정의 첫 번째 단계는 이미 생성된 DynamoDB 테이블을 사용하도록 carts 서비스를 재구성하는 것입니다. 애플리케이션은 대부분의 구성을 ConfigMap에서 로드합니다. 한번 살펴보겠습니다:

```bash
$ kubectl -n carts get -o yaml cm carts
apiVersion: v1
data:
  AWS_ACCESS_KEY_ID: key
  AWS_SECRET_ACCESS_KEY: secret
  CARTS_DYNAMODB_CREATETABLE: true
  CARTS_DYNAMODB_ENDPOINT: http://carts-dynamodb:8000
  CARTS_DYNAMODB_TABLENAME: Items
kind: ConfigMap
metadata:
  name: carts
  namespace: carts
```

또한 브라우저를 사용하여 애플리케이션의 현재 상태를 확인하세요. `ui` 네임스페이스에 `LoadBalancer` 유형의 서비스인 `ui-nlb`가 프로비저닝되어 있어 이를 통해 애플리케이션의 UI에 접근할 수 있습니다.

```bash
$ kubectl -n ui get service ui-nlb -o jsonpath='{.status.loadBalancer.ingress[*].hostname}{"\n"}'
k8s-ui-uinlb-647e781087-6717c5049aa96bd9.elb.us-west-2.amazonaws.com
```

위 명령에서 생성된 URL을 사용하여 브라우저에서 UI를 엽니다. 아래와 같이 Retail Store가 열려야 합니다.

![Home](/img/sample-app-screens/home.webp)

다음 kustomization은 DynamoDB 엔드포인트 구성을 제거하여 ConfigMap을 덮어씁니다. 이는 SDK가 테스트 Pod 대신 실제 DynamoDB 서비스를 사용하도록 지시합니다. 또한 이미 생성된 DynamoDB 테이블 이름을 구성했습니다. 테이블 이름은 환경 변수 `CARTS_DYNAMODB_TABLENAME`에서 가져옵니다.

```kustomization
modules/security/eks-pod-identity/dynamo/kustomization.yaml
ConfigMap/carts
```

`CARTS_DYNAMODB_TABLENAME`의 값을 확인한 다음 Kustomize를 실행하여 실제 DynamoDB 서비스를 사용해 보겠습니다:

```bash
$ echo $CARTS_DYNAMODB_TABLENAME
eks-workshop-carts
$ kubectl kustomize ~/environment/eks-workshop/modules/security/eks-pod-identity/dynamo \
  | envsubst | kubectl apply -f-
```

이것은 새로운 값으로 ConfigMap을 덮어쓸 것입니다:

```bash
$ kubectl -n carts get cm carts -o yaml
apiVersion: v1
data:
  CARTS_DYNAMODB_TABLENAME: eks-workshop-carts
kind: ConfigMap
metadata:
  labels:
    app: carts
  name: carts
  namespace: carts
```

이제 새로운 ConfigMap 내용을 적용하기 위해 모든 carts pod를 재시작해야 합니다:

```bash expectError=true hook=enable-dynamo
$ kubectl rollout restart -n carts deployment/carts
deployment.apps/carts restarted
$ kubectl rollout status -n carts deployment/carts --timeout=20s
Waiting for deployment "carts" rollout to finish: 1 old replicas are pending termination...
error: timed out waiting for the condition
```

변경 사항이 제대로 배포되지 않은 것 같습니다. Pod를 확인하여 이를 확인할 수 있습니다:

```bash
$ kubectl -n carts get pod
NAME                              READY   STATUS             RESTARTS        AGE
carts-5d486d7cf7-8qxf9            1/1     Running            0               5m49s
carts-df76875ff-7jkhr             0/1     CrashLoopBackOff   3 (36s ago)     2m2s
carts-dynamodb-698674dcc6-hw2bg   1/1     Running            0               20m
```

무엇이 잘못되었을까요?