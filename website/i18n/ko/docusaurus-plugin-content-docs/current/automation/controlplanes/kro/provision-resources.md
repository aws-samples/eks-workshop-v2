---
title: "kro로 리소스 생성하기"
sidebar_position: 5
tmdTranslationSourceHash: 'b9394e7175a82507b6f33e051b9ffbe3'
---

이제 kro가 설치되었으므로, kro WebApplication ResourceGraphDefinition을 사용하여 **Carts** 컴포넌트를 배포하겠습니다. 먼저 재사용 가능한 WebApplication API를 정의하는 ResourceGraphDefinition 템플릿을 살펴보겠습니다:

<details>
  <summary>전체 RGD 매니페스트 펼치기</summary>

::yaml{file="manifests/modules/automation/controlplanes/kro/rgds/webapp-rgd.yaml"}

</details>

이 ResourceGraphDefinition은 다음을 배포하는 복잡성을 추상화하는 커스텀 `WebApplication` API를 생성합니다:

- ServiceAccount
- ConfigMap
- Deployment
- Service
- Ingress (선택 사항)

스키마는 다음과 같이 애플리케이션 이미지, 레플리카 수, 환경 변수, 헬스 체크 구성과 같은 주요 매개변수의 커스터마이징을 허용하면서 합리적인 기본값을 제공합니다:

::yaml{file="manifests/modules/automation/controlplanes/kro/rgds/webapp-rgd.yaml" zoomPath="spec.schema.spec" zoomBefore="0"}

:::info
스키마가 기본값과 타입 정의를 사용하여 기본 Kubernetes 복잡성을 숨기는 개발자 친화적인 API를 생성하는 방법을 주목하세요.
:::

이 WebApplication ResourceGraphDefinition을 사용하여 인메모리 데이터베이스를 사용하는 **Carts** 컴포넌트의 인스턴스를 생성하겠습니다. 이를 위해 먼저 기존 carts 배포를 정리하겠습니다:

```bash
$ kubectl delete all --all -n carts
pod "carts-68d496fff8-9lcpc" deleted
pod "carts-dynamodb-995f7768c-wtsbr" deleted
service "carts" deleted
service "carts-dynamodb" deleted
deployment.apps "carts" deleted
deployment.apps "carts-dynamodb" deleted
```

다음으로 WebApplication API를 등록하기 위해 ResourceGraphDefinition을 적용합니다:

```bash wait=10
$ kubectl apply -f ~/environment/eks-workshop/modules/automation/controlplanes/kro/rgds/webapp-rgd.yaml
resourcegraphdefinition.kro.run/web-application created
```

이것은 WebApplication API를 등록합니다. kro는 RGD 스키마를 기반으로 Custom Resource Definition (CRD)을 자동으로 생성합니다. CRD를 확인해보세요:

```bash
$ kubectl get crd webapplications.kro.run
NAME                       CREATED AT
webapplications.kro.run    2024-01-15T10:30:00Z
```

이제 WebApplication API를 사용하여 **Carts** 컴포넌트의 인스턴스를 생성할 `carts.yaml` 파일을 살펴보겠습니다:

::yaml{file="manifests/modules/automation/controlplanes/kro/app/carts.yaml" paths="kind,metadata,spec.appName,spec.replicas,spec.image,spec.port,spec.env,spec.service"}

1. RGD에서 생성한 커스텀 WebApplication API를 사용합니다
2. `carts` 네임스페이스에 `carts`라는 이름의 리소스를 생성합니다
3. 리소스 이름 지정을 위한 애플리케이션 이름을 지정합니다
4. 단일 레플리카를 설정합니다
5. 소매점 카트 서비스 컨테이너 이미지를 사용합니다
6. 8080 포트에서 애플리케이션을 노출합니다
7. 인메모리 지속성 모드를 위한 환경 변수를 구성합니다
8. Kubernetes Service 리소스를 활성화합니다

애플리케이션을 배포해보겠습니다:

```bash wait=30
$ kubectl apply -f ~/environment/eks-workshop/modules/automation/controlplanes/kro/app/carts.yaml
webapplication.kro.run/carts created
```

kro는 이 커스텀 리소스를 처리하고 모든 기본 Kubernetes 리소스를 생성합니다. 커스텀 리소스가 생성되었는지 확인해보겠습니다:

```bash
$ kubectl get webapplication -n carts
NAME    STATE         SYNCED   AGE
carts   IN_PROGRESS   False    16s
```

이제 인스턴스가 "synced" 상태에 도달할 때까지 기다릴 수 있습니다:

```bash
$ kubectl wait -o yaml webapplication/carts -n carts \
  --for=condition=InstanceSynced=True --timeout=120s
```

다음으로, RGD의 컴포넌트가 실행 중인지 확인합니다:

```bash
$ kubectl get all -n carts
NAME                         READY   STATUS    RESTARTS   AGE
pod/carts-7d58cfb7c9-xyz12   1/1     Running   0          30s

NAME            TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
service/carts   ClusterIP   172.20.123.45   <none>        80/TCP    30s

NAME                    READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/carts   1/1     1            1           30s

NAME                               DESIRED   CURRENT   READY   AGE
replicaset.apps/carts-7d58cfb7c9   1         1         1       30s
```

kro는 **Carts** 컴포넌트에 필요한 모든 Kubernetes 리소스의 배포를 단일 단위로 성공적으로 오케스트레이션했습니다. kro를 사용함으로써, 일반적으로 여러 YAML 파일을 적용해야 하는 작업을 단일 선언적 API 호출로 변환했습니다. 이것은 복잡한 리소스 오케스트레이션을 단순화하는 kro의 강력함을 보여줍니다.

다음 섹션에서는 carts에서 현재 사용 중인 인메모리 데이터베이스를 Amazon DynamoDB 테이블로 교체하겠습니다.

