---
title: "애플리케이션 업데이트"
sidebar_position: 25
tmdTranslationSourceHash: '9fc4419f2ed8a6c543ef6ff5f14ad1dd'
---

새로운 리소스가 생성되거나 업데이트되면, 애플리케이션 구성을 조정하여 이러한 새로운 리소스를 활용해야 하는 경우가 많습니다. 환경 변수는 애플리케이션 개발자가 구성을 저장하는 데 널리 사용되는 방법이며, Kubernetes에서는 배포를 생성할 때 컨테이너 [스펙](https://kubernetes.io/docs/tasks/inject-data-application/define-environment-variable-container/)의 `env` 필드를 통해 컨테이너에 환경 변수를 전달할 수 있습니다.

Kubernetes에서 이를 달성하는 두 가지 주요 방법이 있습니다:

1. **ConfigMap**: Kubernetes의 핵심 리소스로, 환경 변수, 텍스트 필드 및 기타 항목과 같은 구성 요소를 키-값 형식으로 전달하여 Pod 스펙에서 사용할 수 있습니다.
2. **Secret**: 기본적으로 암호화되지 않는다는 점을 기억하는 것이 중요하지만, Secret은 비밀번호와 같은 민감한 정보를 저장하는 데 사용됩니다.

이 실습에서는 carts 컴포넌트의 ConfigMap을 업데이트하는 데 중점을 둘 것입니다. 로컬 DynamoDB를 가리키는 구성을 제거하고 대신 Crossplane으로 생성된 DynamoDB 테이블의 이름을 사용합니다:

```kustomization
modules/automation/controlplanes/crossplane/app/kustomization.yaml
ConfigMap/carts
```

또한, carts Pod에 DynamoDB 서비스에 액세스하기 위한 적절한 IAM 권한을 제공해야 합니다. IAM 역할은 이미 생성되었으며, IAM Roles for Service Accounts (IRSA)를 사용하여 이를 carts Pod에 적용합니다:

```kustomization
modules/automation/controlplanes/crossplane/app/carts-serviceAccount.yaml
ServiceAccount/carts
```

IRSA의 작동 방식에 대해 자세히 알아보려면 [공식 문서](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html)를 참조하세요.

이제 새로운 구성을 적용해 보겠습니다:

```bash
$ kubectl kustomize ~/environment/eks-workshop/modules/automation/controlplanes/crossplane/app \
  | envsubst | kubectl apply -f-
```

이제 모든 carts Pod를 재시작하여 새로운 ConfigMap 내용을 적용해야 합니다:

```bash
$ kubectl rollout restart -n carts deployment/carts
deployment.apps/carts restarted
$ kubectl rollout status -n carts deployment/carts --timeout=40s
Waiting for deployment "carts" rollout to finish: 1 old replicas are pending termination...
deployment "carts" successfully rolled out
```

애플리케이션이 새로운 DynamoDB 테이블과 함께 작동하는지 확인하기 위해, 샘플 애플리케이션을 테스트용으로 노출하기 위해 생성된 Network Load Balancer (NLB)를 사용할 수 있습니다. 이를 통해 웹 브라우저를 통해 애플리케이션과 직접 상호 작용할 수 있습니다:

```bash
$ LB_HOSTNAME=$(kubectl -n ui get service ui-nlb -o jsonpath='{.status.loadBalancer.ingress[*].hostname}{"\n"}')
$ echo "http://$LB_HOSTNAME"
http://k8s-ui-uinlb-647e781087-6717c5049aa96bd9.elb.us-west-2.amazonaws.com
```

:::info
이 명령을 실행할 때 실제 엔드포인트는 다를 수 있습니다. 새로운 Network Load Balancer 엔드포인트가 프로비저닝되기 때문입니다.
:::

로드 밸런서 프로비저닝이 완료될 때까지 기다리려면 다음 명령을 실행할 수 있습니다:

```bash timeout=610
$ wait-for-lb $(kubectl get service -n ui ui-nlb -o jsonpath="{.status.loadBalancer.ingress[*].hostname}{'\n'}")
```

로드 밸런서가 프로비저닝되면 웹 브라우저에 URL을 붙여넣어 액세스할 수 있습니다. 웹 스토어의 UI가 표시되며 사용자로서 사이트를 탐색할 수 있습니다.

<Browser url="http://k8s-ui-uinlb-a9797f0f61.elb.us-west-2.amazonaws.com">
<img src={require('@site/static/img/sample-app-screens/home.webp').default}/>
</Browser>

**Carts** 모듈이 방금 프로비저닝한 DynamoDB 테이블을 실제로 사용하고 있는지 확인하려면 장바구니에 몇 가지 항목을 추가해 보세요.

<img src={require('@site/static/img/sample-app-screens/shopping-cart-items.webp').default}/>

DynamoDB 테이블에도 항목이 있는지 확인하려면 다음을 실행하세요:

```bash
$ aws dynamodb scan --table-name "${EKS_CLUSTER_NAME}-carts-crossplane"
```

축하합니다! Kubernetes API의 범위를 벗어나지 않고 AWS 리소스를 성공적으로 생성하고 활용했습니다!

