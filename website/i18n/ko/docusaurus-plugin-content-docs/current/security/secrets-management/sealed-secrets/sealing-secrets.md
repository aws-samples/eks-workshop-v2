---
title: "Secret 봉인하기"
sidebar_position: 433
tmdTranslationSourceHash: '0d58a7c004d07480c7b8c02ef63cf83c'
---

### Catalog Pod 살펴보기

현재 `catalog` Deployment는 환경 변수를 통해 `catalog-db` Secret에서 데이터베이스 자격 증명에 액세스합니다:

- `RETAIL_CATALOG_PERSISTENCE_USER`
- `RETAIL_CATALOG_PERSISTENCE_PASSWORD`

이는 `envFrom`을 사용하여 Secret을 참조하는 방식으로 수행됩니다:

```bash
$ kubectl -n catalog get deployment catalog -o yaml | yq '.spec.template.spec.containers[] | .envFrom'

- configMapRef:
    name: catalog
- secretRef:
    name: catalog-db
```

`catalog-db` Secret을 살펴보면 base64로만 인코딩되어 있어 다음과 같이 쉽게 디코딩할 수 있으므로 GitOps 워크플로의 일부로 Secret 매니페스트를 포함하기 어렵다는 것을 알 수 있습니다.

```file
manifests/base-application/catalog/secrets.yaml
```

```bash
$ kubectl -n catalog get secrets catalog-db --template {{.data.RETAIL_CATALOG_PERSISTENCE_USER}} | base64 -d
catalog%
$ kubectl -n catalog get secrets catalog-db --template {{.data.RETAIL_CATALOG_PERSISTENCE_PASSWORD}} | base64 -d
dYmNfWV4uEvTzoFu%
```

새로운 Secret `catalog-sealed-db`를 생성해 보겠습니다. `catalog-db` Secret과 동일한 키와 값을 가진 새 파일 `new-catalog-db.yaml`을 생성하겠습니다.

```file
manifests/modules/security/sealed-secrets/new-catalog-db.yaml
```

이제 `kubeseal`을 사용하여 SealedSecret YAML 매니페스트를 생성해 보겠습니다.

```bash
$ kubeseal --format=yaml < ~/environment/eks-workshop/modules/security/sealed-secrets/new-catalog-db.yaml \
  > /tmp/sealed-catalog-db.yaml
```

또는 컨트롤러에서 공개 키를 가져와서 오프라인으로 Secret을 봉인하는 데 사용할 수 있습니다:

```bash test=false
$ kubeseal --fetch-cert > /tmp/public-key-cert.pem
$ kubeseal --cert=/tmp/public-key-cert.pem --format=yaml < ~/environment/eks-workshop/modules/security/sealed-secrets/new-catalog-db.yaml \
  > /tmp/sealed-catalog-db.yaml
```

다음 내용으로 sealed-secret이 생성됩니다:

```yaml
apiVersion: bitnami.com/v1alpha1
kind: SealedSecret
metadata:
  creationTimestamp: null
  name: catalog-sealed-db
  namespace: catalog
spec:
  encryptedData:
    password: AgBe(...)R91c
    username: AgBu(...)Ykc=
  template:
    data: null
    metadata:
      creationTimestamp: null
      name: catalog-sealed-db
      namespace: catalog
    type: Opaque
```

SealedSecret을 EKS 클러스터에 배포해 보겠습니다:

```bash
$ kubectl apply -f /tmp/sealed-catalog-db.yaml
```

컨트롤러 로그를 보면 방금 배포된 SealedSecret 커스텀 리소스를 감지하여 일반 Secret을 생성하기 위해 봉인을 해제하는 것을 알 수 있습니다.

```bash
$ kubectl logs deployments/sealed-secrets-controller -n kube-system

2022/11/07 04:28:27 Updating catalog/catalog-sealed-db
2022/11/07 04:28:27 Event(v1.ObjectReference{Kind:"SealedSecret", Namespace:"catalog", Name:"catalog-sealed-db", UID:"a2ae3aef-f475-40e9-918c-697cd8cfc67d", APIVersion:"bitnami.com/v1alpha1", ResourceVersion:"23351", FieldPath:""}): type: 'Normal' reason: 'Unsealed' SealedSecret unsealed successfully
```

SealedSecret에서 봉인 해제된 `catalog-sealed-db` Secret이 컨트롤러에 의해 catalog 네임스페이스에 배포되었는지 확인합니다.

```bash
$ kubectl get secret -n catalog catalog-sealed-db

NAME                       TYPE     DATA   AGE
catalog-sealed-db          Opaque   4      7m51s
```

위 Secret을 읽는 **catalog** 배포를 재배포해 보겠습니다. 다음과 같이 `catalog-sealed-db` Secret을 읽도록 `catalog` 배포를 업데이트했습니다:

```kustomization
modules/security/sealed-secrets/deployment.yaml
Deployment/catalog
```

```bash
$ kubectl apply -k ~/environment/eks-workshop/modules/security/sealed-secrets
$ kubectl rollout status -n catalog deployment/catalog --timeout 30s
```

SealedSecret 리소스인 **catalog-sealed-db**는 클러스터에 배포된 DaemonSet, Deployment, ConfigMap 등과 같은 다른 Kubernetes 리소스와 관련된 YAML 매니페스트와 함께 Git 리포지토리에 안전하게 저장할 수 있습니다. 그런 다음 GitOps 워크플로를 사용하여 이러한 리소스의 배포를 클러스터에 관리할 수 있습니다.

