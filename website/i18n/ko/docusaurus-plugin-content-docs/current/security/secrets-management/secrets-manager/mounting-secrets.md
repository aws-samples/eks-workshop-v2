---
title: "Kubernetes Pod에 AWS Secrets Manager 시크릿 마운트하기"
sidebar_position: 423
tmdTranslationSourceHash: '0b07d0bd4408ba68fee8d10501569a50'
---

이제 AWS Secrets Manager에 저장된 시크릿이 Kubernetes Secret과 동기화되었으므로, 이를 Pod 내부에 마운트해 보겠습니다. 먼저 `catalog` Deployment와 `catalog` 네임스페이스의 기존 Secret을 살펴보겠습니다.

현재 `catalog` Deployment는 환경 변수를 통해 `catalog-db` 시크릿에서 데이터베이스 자격 증명에 액세스합니다:

- `RETAIL_CATALOG_PERSISTENCE_USER`
- `RETAIL_CATALOG_PERSISTENCE_PASSWORD`

이는 `envFrom`으로 Secret을 참조하여 수행됩니다:

```bash
$ kubectl -n catalog get deployment catalog -o yaml | yq '.spec.template.spec.containers[] | .envFrom'

- configMapRef:
    name: catalog
- secretRef:
    name: catalog-db
```

`catalog` Deployment는 현재 `/tmp`에 마운트된 `emptyDir`을 제외하고 추가 `volumes` 또는 `volumeMounts`가 없습니다:

```bash
$ kubectl -n catalog get deployment catalog -o yaml | yq '.spec.template.spec.volumes'
- emptyDir:
    medium: Memory
  name: tmp-volume
$ kubectl -n catalog get deployment catalog -o yaml | yq '.spec.template.spec.containers[] | .volumeMounts'
- mountPath: /tmp
  name: tmp-volume
```

`catalog` Deployment를 수정하여 AWS Secrets Manager에 저장된 시크릿을 자격 증명 소스로 사용하도록 하겠습니다:

```kustomization
modules/security/secrets-manager/mounting-secrets/kustomization.yaml
Deployment/catalog
```

이전에 검증한 SecretProviderClass를 사용하여 CSI 드라이버로 AWS Secrets Manager 시크릿을 Pod 내부의 `/etc/catalog-secret` mountPath에 마운트하겠습니다. 이렇게 하면 AWS Secrets Manager가 저장된 시크릿 내용을 Amazon EKS와 동기화하고 Pod에서 환경 변수로 사용할 수 있는 Kubernetes Secret을 생성합니다.

```bash
$ kubectl kustomize ~/environment/eks-workshop/modules/security/secrets-manager/mounting-secrets/ \
  | envsubst | kubectl apply -f-
$ kubectl rollout status -n catalog deployment/catalog --timeout=120s
```

`catalog` 네임스페이스에서 변경된 내용을 확인해 보겠습니다.

이제 Deployment에는 CSI Secret Store Driver를 사용하고 `/etc/catalog-secret`에 마운트되는 새로운 `volume`과 해당 `volumeMount`가 있습니다:

```bash
$ kubectl -n catalog get deployment catalog -o yaml | yq '.spec.template.spec.volumes'
- csi:
    driver: secrets-store.csi.k8s.io
    readOnly: true
    volumeAttributes:
      secretProviderClass: catalog-spc
  name: catalog-secret
- emptyDir:
    medium: Memory
  name: tmp-volume
$ kubectl -n catalog get deployment catalog -o yaml | yq '.spec.template.spec.containers[] | .volumeMounts'
- mountPath: /etc/catalog-secret
  name: catalog-secret
  readOnly: true
- mountPath: /tmp
  name: tmp-volume
```

마운트된 Secret은 Pod의 컨테이너 파일시스템 내부에서 파일로 민감한 정보에 액세스하는 안전한 방법을 제공합니다. 이 접근 방식은 시크릿 값을 환경 변수로 노출하지 않고 소스 Secret이 수정될 때 자동 업데이트되는 등 여러 이점을 제공합니다.

Pod 내부에 마운트된 Secret의 내용을 살펴보겠습니다:

```bash
$ kubectl -n catalog exec deployment/catalog -- ls /etc/catalog-secret/
eks-workshop-catalog-secret-WDD8yS
password
username
$ kubectl -n catalog exec deployment/catalog -- cat /etc/catalog-secret/${SECRET_NAME}
{"username":"catalog", "password":"dYmNfWV4uEvTzoFu"}
$ kubectl -n catalog exec deployment/catalog -- cat /etc/catalog-secret/username
catalog
$ kubectl -n catalog exec deployment/catalog -- cat /etc/catalog-secret/password
dYmNfWV4uEvTzoFu
```

:::info
CSI 드라이버를 사용하여 AWS Secrets Manager에서 시크릿을 마운트하면 mountPath에 세 개의 파일이 생성됩니다:

1. 전체 JSON 값을 포함하는 AWS 시크릿 이름의 파일
2. SecretProviderClass에 정의된 jmesPath 표현식을 통해 추출된 각 키에 대한 개별 파일
   :::

환경 변수는 이제 CSI Secret Store 드라이버를 통해 SecretProviderClass에 의해 자동으로 생성된 새로운 `catalog-secret`에서 가져옵니다:

```bash
$ kubectl -n catalog get deployment catalog -o yaml | yq '.spec.template.spec.containers[] | .env'
- name: RETAIL_CATALOG_PERSISTENCE_USER
  valueFrom:
    secretKeyRef:
      key: username
      name: catalog-secret
- name: RETAIL_CATALOG_PERSISTENCE_PASSWORD
  valueFrom:
    secretKeyRef:
      key: password
      name: catalog-secret
$ kubectl -n catalog get secrets
NAME             TYPE     DATA   AGE
catalog-db       Opaque   2      15h
catalog-secret   Opaque   2      43s
```

실행 중인 Pod에서 환경 변수가 올바르게 설정되었는지 확인할 수 있습니다:

```bash
$ kubectl -n catalog exec -ti deployment/catalog -- env | grep PERSISTENCE
RETAIL_CATALOG_PERSISTENCE_ENDPOINT=catalog-mysql:3306
RETAIL_CATALOG_PERSISTENCE_PASSWORD=dYmNfWV4uEvTzoFu
RETAIL_CATALOG_PERSISTENCE_PROVIDER=mysql
RETAIL_CATALOG_PERSISTENCE_DB_NAME=catalog
RETAIL_CATALOG_PERSISTENCE_USER=catalog
```

이제 시크릿 관리의 모범 사례인 시크릿 로테이션을 활용할 수 있는 AWS Secrets Manager와 완전히 통합된 Kubernetes Secret을 갖게 되었습니다. AWS Secrets Manager에서 시크릿이 로테이션되거나 업데이트되면 Deployment의 새 버전을 롤아웃하여 CSI Secret Store 드라이버가 Kubernetes Secret 내용을 업데이트된 값과 동기화할 수 있습니다.

