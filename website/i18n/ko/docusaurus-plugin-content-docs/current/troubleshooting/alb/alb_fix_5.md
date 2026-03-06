---
title: "IAM 정책 문제"
sidebar_position: 31
tmdTranslationSourceHash: 5f51c26fd2fef5b5078614ccdff8f7ee
---

이 섹션에서는 AWS Load Balancer Controller가 Application Load Balancer를 생성하고 관리하는 데 필요한 IAM 권한이 부족한 문제를 해결합니다. IAM 정책 구성을 식별하고 수정하는 과정을 살펴보겠습니다.

### 1단계: Service Account Role 확인

먼저 Load Balancer Controller가 사용하는 Service Account를 살펴보겠습니다. Controller는 IAM Roles for Service Accounts (IRSA)를 사용하여 AWS API를 호출합니다:

```bash
$ kubectl get serviceaccounts -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller -o yaml
```

출력 예시:

::yaml{file="manifests/modules/troubleshooting/alb/files/iam_issue_service_account_role.yaml" paths="items.0.metadata.annotations"}

1. `eks.amazonaws.com/role-arn`: 이 태그는 올바른 권한이 필요한 IAM role을 참조합니다.

### 2단계: Controller 로그 확인

Load Balancer Controller 로그를 확인하여 권한 문제를 파악해보겠습니다:

```bash wait=25  expectError=true
$ kubectl logs -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller
```

다음과 같은 오류가 표시될 수 있습니다:

```text
{"level":"error","ts":"2024-06-11T14:24:24Z","msg":"Reconciler error","controller":"ingress","object":{"name":"ui","namespace":"ui"},"namespace":"ui","name":"ui","reconcileID":"49d27bbb-96e5-43b4-b115-b7a07e757148","error":"AccessDenied: User: arn:aws:sts::xxxxxxxxxxxx:assumed-role/alb-controller-20240611131524228000000002/1718115201989397805 is not authorized to perform: elasticloadbalancing:CreateLoadBalancer on resource: arn:aws:elasticloadbalancing:us-west-2:xxxxxxxxxxxx:loadbalancer/app/k8s-ui-ui-5ddc3ba496/* because no identity-based policy allows the elasticloadbalancing:CreateLoadBalancer action\n\tstatus code: 403, request id: a24a1620-3a75-46b7-b3c3-9c80fada159e"}
```

이 오류는 IAM role에 `elasticloadbalancing:CreateLoadBalancer` 권한이 없음을 나타냅니다.

### 3단계: IAM 정책 수정

이 문제를 해결하기 위해 올바른 권한으로 IAM role을 업데이트해야 합니다. 이 워크샵에서는 AWS Load Balancer Controller의 [설치 가이드](https://docs.aws.amazon.com/eks/latest/userguide/lbc-helm.html)를 기반으로 필요한 IAM 정책 권한이 포함된 올바른 정책을 미리 생성했습니다:

이제 다음을 수행합니다:

#### 3.1. 올바른 정책 연결

```bash
$ aws iam attach-role-policy \
    --role-name ${LOAD_BALANCER_CONTROLLER_ROLE_NAME} \
    --policy-arn ${LOAD_BALANCER_CONTROLLER_POLICY_ARN_FIX}
```

#### 3.2. 잘못된 정책 제거

```bash
$ aws iam detach-role-policy \
    --role-name ${LOAD_BALANCER_CONTROLLER_ROLE_NAME} \
    --policy-arn ${LOAD_BALANCER_CONTROLLER_POLICY_ARN_ISSUE}
```

#### 3.3. Load Balancer Controller를 재시작하여 새 서브넷 구성을 적용

```bash
$ kubectl -n kube-system rollout restart deploy aws-load-balancer-controller
deployment.apps/aws-load-balancer-controller restarted
$ kubectl -n kube-system wait --for=condition=available deployment/aws-load-balancer-controller
```

### 4단계: 수정 확인

이제 ingress가 ALB로 올바르게 구성되었는지 확인합니다:

```bash timeout=600 hook=fix-5 hookTimeout=600
$ kubectl get ingress -n ui ui -o jsonpath="{.status.loadBalancer.ingress[*].hostname}{'\n'}"
k8s-ui-ui-5ddc3ba496-1208241872.us-west-2.elb.amazonaws.com
```

:::tip
**Load Balancer 생성에는 몇 분이 걸릴 수 있습니다**. 다음을 통해 프로세스를 확인할 수 있습니다:

1. CloudTrail에서 성공적인 `CreateLoadBalancer` API 호출 확인
2. Controller 로그에서 성공적인 생성 메시지 모니터링
3. ingress 리소스에서 ALB DNS 이름이 나타나는지 확인

:::

참고로 AWS Load Balancer Controller에 필요한 전체 권한 세트는 [공식 문서](https://kubernetes-sigs.github.io/aws-load-balancer-controller/latest/deploy/installation/#setup-iam-manually)에서 확인할 수 있습니다.

