---
title: "고급 트러블슈팅"
sidebar_position: 23
tmdTranslationSourceHash: b2128fa90940138d820b4fbf911c468c
---

이 섹션에서는 Amazon Q CLI와 [Amazon EKS MCP 서버](https://awslabs.github.io/mcp/servers/eks-mcp-server/)를 사용하여 Kubernetes, EKS 및 기타 AWS 서비스에 대한 지식 없이는 해결하기 어려운 EKS 클러스터의 복잡한 문제를 트러블슈팅합니다.

먼저 carts 서비스가 생성된 DynamoDB 테이블을 사용하도록 재구성하겠습니다. 애플리케이션은 ConfigMap에서 대부분의 구성을 로드합니다. 현재 ConfigMap을 살펴보겠습니다:

```bash
$ kubectl -n carts get -o yaml cm carts
apiVersion: v1
data:
  AWS_ACCESS_KEY_ID: key
  AWS_SECRET_ACCESS_KEY: secret
  RETAIL_CART_PERSISTENCE_DYNAMODB_CREATE_TABLE: "true"
  RETAIL_CART_PERSISTENCE_DYNAMODB_ENDPOINT: http://carts-dynamodb:8000
  RETAIL_CART_PERSISTENCE_DYNAMODB_TABLE_NAME: Items
  RETAIL_CART_PERSISTENCE_PROVIDER: dynamodb
kind: ConfigMap
metadata:
  name: carts
  namespace: carts
```

다음 kustomization을 사용하여 ConfigMap을 업데이트합니다. 이는 DynamoDB 엔드포인트 구성을 제거하여 SDK가 테스트 Pod 대신 실제 DynamoDB 서비스를 사용하도록 지시합니다. 또한 환경 변수 `RETAIL_CART_PERSISTENCE_DYNAMODB_TABLE_NAME`에 이미 생성된 DynamoDB 테이블 이름을 구성했습니다:

```kustomization
modules/aiml/q-cli/troubleshoot/dynamo/kustomization.yaml
ConfigMap/carts
```

DynamoDB 테이블 이름을 확인하고 새 구성을 적용하겠습니다:

```bash
$ echo $CARTS_DYNAMODB_TABLENAME
eks-workshop-carts
$ kubectl kustomize ~/environment/eks-workshop/modules/aiml/q-cli/troubleshoot/dynamo \
  | envsubst | kubectl apply -f-
```

업데이트된 ConfigMap을 확인합니다:

```bash
$ kubectl -n carts get cm carts -o yaml
apiVersion: v1
data:
  RETAIL_CART_PERSISTENCE_DYNAMODB_TABLE_NAME: eks-workshop-carts
  RETAIL_CART_PERSISTENCE_PROVIDER: dynamodb
kind: ConfigMap
metadata:
  labels:
    app: carts
  name: carts
  namespace: carts
```

이제 carts 배포를 다시 배포하여 새 ConfigMap 내용을 가져오겠습니다:

```bash expectError=true hook=enable-dynamo
$ kubectl rollout restart -n carts deployment/carts
deployment.apps/carts restarted
$ kubectl rollout status -n carts deployment/carts --timeout=20s
Waiting for deployment "carts" rollout to finish: 1 old replicas are pending termination...
error: timed out waiting for the condition
```

배포가 실패한 것 같습니다. Pod 상태를 확인해 보겠습니다:

```bash
$ kubectl -n carts get pod
NAME                              READY   STATUS             RESTARTS        AGE
carts-5d486d7cf7-8qxf9            1/1     Running            0               5m49s
carts-df76875ff-7jkhr             0/1     CrashLoopBackOff   3 (36s ago)     2m2s
carts-dynamodb-698674dcc6-hw2bg   1/1     Running            0               20m
```

Amazon Q CLI를 사용하여 이 문제를 조사하겠습니다. 새 Q CLI 세션을 시작합니다:

```bash test=false
$ q chat
```

Q CLI에 문제 트러블슈팅을 요청합니다:

```text
I have a pod in my eks-workshop cluster that is with status CrashLoopBackOff. Troubleshoot the issue and resolve it for me.
```

프롬프트를 처리하기 위해 Q CLI는 MCP 서버의 다양한 도구를 사용합니다. 이전 예제에서 본 도구 외에도 다음을 수행할 수 있습니다:

1. EKS MCP 서버의 `get_policies_for_role` 도구를 사용하여 범위 내 IAM role 및 정책 설명
2. Q CLI에 내장된 `use_aws` 도구로 AWS 리소스 관련 추가 정보 가져오기
3. 문제를 해결하기 위한 시정 조치 수행

Q CLI가 제공하는 제안 사항을 따라 이 문제를 해결하세요. 이상적인 시나리오에서는 문제가 해결되어야 합니다. 마지막으로 Q CLI는 수행한 단계의 최종 상태 요약을 제공합니다.

<details>
  <summary>샘플 응답 확장</summary>

```text
Perfect! The CrashLoopBackOff issue has been successfully resolved. Here's a summary of what I found and fixed:

## Problem Analysis

The pod carts-d49c67c77-k2zvz in the carts namespace was in CrashLoopBackOff state with:
• **Restart count:** 9 restarts
• **Exit code:** 1 (error)
• **Root cause:** DynamoDB permissions issue

## Root Cause

The application logs showed this error:
User: arn:aws:sts::1234567890:assumed-role/eks-workshop-carts-dynamo/eks-eks-worksh-carts-d49c-c1857ccc-86be-4bd6-9c6d-0b90748341b4 is not authorized to perform: dynamodb:Query on resource: arn:aws:dynamodb:us-west-2:1234567890:table/eks-workshop-carts/index/idx_global_customerId because no identity-based policy allows the dynamodb:Query action


The IAM role eks-workshop-carts-dynamo had a policy that granted access to a table named wrong-table-name, but the application was trying to access eks-workshop-carts.

## Solution Applied

1. Identified the correct DynamoDB table: eks-workshop-carts
2. Added proper IAM permissions: Created an inline policy CartsTableAccess with the following permissions:
   • Actions: dynamodb:GetItem, PutItem, UpdateItem, DeleteItem, Query, Scan, BatchGetItem, BatchWriteItem
   • Resources: arn:aws:dynamodb:us-west-2:1234567890:table/eks-workshop-carts and its indexes
3. Restarted the pod: Deleted the failing pod to allow the deployment to create a new one with the updated permissions

## Result

The new pod carts-d49c67c77-mks7h is now:
• **Status:** Running and Ready
• **Restart count:** 0
• **Application:** Successfully started and connected to DynamoDB
• **Health checks:** Passing (both liveness and readiness probes)

The CrashLoopBackOff issue has been completely resolved, and the carts service is now functioning properly with correct DynamoDB access permissions.
```

</details>

작업이 완료되면 다음 명령을 입력하여 Q CLI 세션을 종료합니다.

```text
/quit
```

마지막으로 Pod가 이제 올바르게 실행되고 있는지 확인합니다:

```bash test=false
$ kubectl -n carts get pod
NAME                              READY   STATUS    RESTARTS   AGE
carts-596b6f94df-q4449            1/1     Running   0          9m5s
carts-dynamodb-698fcb695f-zvzf5   1/1     Running   0          2d1h
```

Amazon Q CLI 소개를 마칩니다. 이 강력한 도구가 EKS용 MCP 서버와 결합하여 EKS 클러스터의 복잡한 문제를 진단하고 해결하는 데 어떻게 도움이 되는지 확인했습니다.

