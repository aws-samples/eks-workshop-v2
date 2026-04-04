---
title: "클라우드 리소스 프로비저닝"
sidebar_position: 6
tmdTranslationSourceHash: '17f0d5b57c14688e84d2e0e3989a323b'
---

이 섹션에서는 carts에서 사용 중인 인메모리 데이터베이스를 DynamoDB로 교체하겠습니다. 기본 WebApplication 템플릿을 기반으로 구축하는 WebApplicationDynamoDB ResourceGraphDefinition을 구성하여 이를 수행하겠습니다.

먼저 이전 섹션에서 생성한 kro 인스턴스를 삭제하겠습니다:

```bash
$ kubectl delete webapplication.kro.run/carts -n carts
webapplication.kro.run "carts" deleted
```

이렇게 하면 관련된 모든 리소스가 정리됩니다:

```bash
$ kubectl get all -n carts
No resources found in carts namespace.
```

이제 재사용 가능한 WebApplicationDynamoDB API를 정의하는 ResourceGraphDefinition 템플릿을 살펴보겠습니다:

<details>
  <summary>전체 RGD 매니페스트 확장</summary>

::yaml{file="manifests/modules/automation/controlplanes/kro/rgds/webapp-dynamodb-rgd.yaml"}

</details>

이 ResourceGraphDefinition은:

1. WebApplication RGD를 구성하는 사용자 정의 `WebApplicationDynamoDB` API를 생성합니다
2. ACK를 사용하여 DynamoDB 테이블을 프로비저닝합니다
3. DynamoDB 액세스를 위한 IAM 역할 및 정책을 생성합니다
4. 애플리케이션 Pod에서 안전한 액세스를 위해 EKS Pod Identity를 구성합니다

EKS Pod Identity에 대해 자세히 알아보려면 [공식 문서](https://docs.aws.amazon.com/eks/latest/userguide/pod-identities.html)를 참조하세요.

:::info
이 RGD가 리소스 섹션에 WebApplication RGD를 포함하고 있는 것을 주목하세요. `webApplication`을 참조함으로써 이 템플릿은 기본 WebApplication RGD에 정의된 모든 Kubernetes 리소스를 재사용하면서 DynamoDB, IAM 및 Pod Identity 리소스를 추가합니다.
:::

ResourceGraphDefinition을 적용하여 WebApplicationDynamoDB API를 등록하겠습니다:

```bash wait=10
$ kubectl apply -f ~/environment/eks-workshop/modules/automation/controlplanes/kro/rgds/webapp-dynamodb-rgd.yaml
resourcegraphdefinition.kro.run/web-application-ddb created
```

이렇게 하면 WebApplicationDynamoDB API가 등록됩니다. Custom Resource Definition (CRD)을 확인하세요:

```bash
$ kubectl get crd webapplicationdynamodbs.kro.run
NAME                               CREATED AT
webapplicationdynamodbs.kro.run    2024-01-15T10:35:00Z
```

이제 WebApplicationDynamoDB API를 사용하여 **Carts** 컴포넌트의 인스턴스를 생성할 carts-ddb.yaml 파일을 살펴보겠습니다:

::yaml{file="manifests/modules/automation/controlplanes/kro/app/carts-ddb.yaml" paths="kind,metadata,spec.appName,spec.replicas,spec.image,spec.port,spec.dynamodb,spec.env,spec.aws"}

1. RGD에서 생성한 사용자 정의 WebApplicationDynamoDB API를 사용합니다
2. `carts` 네임스페이스에 `carts`라는 이름의 리소스를 생성합니다
3. 리소스 이름 지정을 위한 애플리케이션 이름을 지정합니다
4. 단일 레플리카를 설정합니다
5. 소매점 장바구니 서비스 컨테이너 이미지를 사용합니다
6. 포트 8080에 애플리케이션을 노출합니다
7. DynamoDB 테이블 이름을 지정합니다
8. DynamoDB 지속성 모드를 활성화하기 위한 환경 변수를 설정합니다
9. IAM 및 Pod Identity 구성을 위한 AWS 계정 ID와 리전을 제공합니다

다음으로 carts-ddb.yaml 파일을 활용하여 업데이트된 컴포넌트를 배포하겠습니다:

```bash wait=10
$ kubectl kustomize ~/environment/eks-workshop/modules/automation/controlplanes/kro/app \
  | envsubst | kubectl apply -f-
webapplicationdynamodb.kro.run/carts created
```

kro는 이 사용자 정의 리소스를 처리하고 DynamoDB 테이블을 포함한 모든 기본 리소스를 생성합니다. 사용자 정의 리소스가 생성되었는지 확인하겠습니다:

```bash
$ kubectl get webapplicationdynamodb -n carts
NAME    STATE         SYNCED   AGE
carts   IN_PROGRESS   False    16s
```

이제 인스턴스가 "synced" 상태에 도달할 때까지 기다릴 수 있습니다:

```bash
$ kubectl wait -o yaml webapplicationdynamodb/carts -n carts \
  --for=condition=InstanceSynced=True --timeout=120s
```

DynamoDB 테이블이 생성되었는지 확인하기 위해 생성된 ACK 리소스를 확인할 수 있습니다:

```bash timeout=300
$ kubectl wait table.dynamodb.services.k8s.aws items -n carts --for=condition=ACK.ResourceSynced --timeout=15m
table.dynamodb.services.k8s.aws/items condition met
$ kubectl get table.dynamodb.services.k8s.aws items -n carts -ojson | yq '.status."tableStatus"'
ACTIVE
```

AWS CLI를 사용하여 테이블이 생성되었는지 확인하겠습니다:

```bash
$ aws dynamodb list-tables

{
    "TableNames": [
        "eks-workshop-carts-kro"
    ]
}
```

kro의 구성 가능한 접근 방식을 사용하여 DynamoDB 테이블과 컴포넌트가 성공적으로 생성되었습니다.

컴포넌트가 새 DynamoDB 테이블과 함께 작동하는지 확인하기 위해 브라우저를 통해 상호 작용할 수 있습니다. 테스트를 위해 샘플 애플리케이션을 노출하는 NLB가 생성되었습니다:

```bash
$ ADDRESS=$(kubectl get ingress -n ui ui -o jsonpath="{.status.loadBalancer.ingress[*].hostname}")
$ echo "http://${ADDRESS}"
http://k8s-ui-ui-a9797f0f61.elb.us-west-2.amazonaws.com
```

:::info
새로운 Network Load Balancer 엔드포인트가 프로비저닝되므로 이 명령을 실행할 때 실제 엔드포인트는 다를 것입니다.
:::

로드 밸런서 프로비저닝이 완료되었는지 확인하려면 다음 명령을 실행할 수 있습니다:

```bash timeout=610
curl --head -X GET --retry 30 --retry-all-errors --retry-delay 15 --connect-timeout 30 --max-time 60 \
  -k $(kubectl get ingress -n ui ui -o jsonpath="{.status.loadBalancer.ingress[*].hostname}")
```

로드 밸런서가 프로비저닝되면 웹 브라우저에 URL을 붙여넣어 액세스할 수 있습니다. 웹 스토어의 UI가 표시되며 사용자로서 사이트를 탐색할 수 있습니다.

<Browser url="http://k8s-ui-ui-a9797f0f61.elb.us-west-2.amazonaws.com/">
<img src={require('@site/static/img/sample-app-screens/home.webp').default}/>
</Browser>

**Carts** 모듈이 방금 프로비저닝한 DynamoDB 테이블을 실제로 사용하고 있는지 확인하려면 장바구니에 몇 가지 항목을 추가해 보세요.

<img src={require('@site/static/img/sample-app-screens/shopping-cart-items.webp').default}/>

이러한 항목이 DynamoDB 테이블에도 있는지 확인하려면 다음을 실행하세요:

```bash
$ aws dynamodb scan --table-name "${EKS_CLUSTER_NAME}-carts-kro"
```

축하합니다! 기본 WebApplication 템플릿을 기반으로 구축하여 DynamoDB 스토리지를 추가함으로써 kro의 구성 가능성을 성공적으로 시연했습니다.

