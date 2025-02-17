---
title: "시크릿 봉인하기"
sidebar_position: 433
---

### catalog Pod 살펴보기

`catalog` 네임스페이스의 `catalog` 디플로이먼트는 catalog-db 시크릿에서 다음 데이터베이스 값들을 환경 변수로 접근합니다:

- `DB_USER`
- `DB_PASSWORD`

```bash
$ kubectl -n catalog get deployment catalog -o yaml | yq '.spec.template.spec.containers[] | .env'

- name: DB_USER
  valueFrom:
    secretKeyRef:
      key: username
      name: catalog-db
- name: DB_PASSWORD
  valueFrom:
    secretKeyRef:
      key: password
      name: catalog-db
- name: DB_NAME
  valueFrom:
    configMapKeyRef:
      key: name
      name: catalog
- name: DB_READ_ENDPOINT
  valueFrom:
    secretKeyRef:
      key: endpoint
      name: catalog-db
- name: DB_ENDPOINT
  valueFrom:
    secretKeyRef:
      key: endpoint
      name: catalog-db
```

`catalog-db` 시크릿을 살펴보면 base64로만 인코딩되어 있어 쉽게 디코딩할 수 있음을 알 수 있습니다. 이는 시크릿 매니페스트를 GitOps 워크플로우의 일부로 사용하기 어렵게 만듭니다.

```file
manifests/base-application/catalog/secrets.yaml
```

```bash
$ kubectl -n catalog get secrets catalog-db --template {{.data.username}} | base64 -d
catalog_user%
$ kubectl -n catalog get secrets catalog-db --template {{.data.password}} | base64 -d
default_password%
```

새로운 시크릿 `catalog-sealed-db`를 만들어보겠습니다. `catalog-db` 시크릿과 동일한 키와 값을 가진 새 파일 `new-catalog-db.yaml`을 생성하겠습니다.

```file
manifests/modules/security/sealed-secrets/new-catalog-db.yaml
```

이제 kubeseal을 사용하여 SealedSecret YAML 매니페스트를 생성해보겠습니다.

```bash
$ kubeseal --format=yaml < ~/environment/eks-workshop/modules/security/sealed-secrets/new-catalog-db.yaml \
  > /tmp/sealed-catalog-db.yaml
```

또는 컨트롤러에서 공개 키를 가져와 오프라인에서 시크릿을 봉인하는 데 사용할 수 있습니다:

```bash test=false
$ kubeseal --fetch-cert > /tmp/public-key-cert.pem
$ kubeseal --cert=/tmp/public-key-cert.pem --format=yaml < ~/environment/eks-workshop/modules/security/sealed-secrets/new-catalog-db.yaml \
  > /tmp/sealed-catalog-db.yaml
```

다음과 같은 내용의 sealed-secret이 생성됩니다:

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

EKS 클러스터에 SealedSecret을 배포해보겠습니다:

```bash
$ kubectl apply -f /tmp/sealed-catalog-db.yaml
```

컨트롤러 로그를 보면 방금 배포된 SealedSecret 커스텀 리소스를 감지하고, 이를 해제하여 일반 시크릿을 생성하는 것을 확인할 수 있습니다.

```bash
$ kubectl logs deployments/sealed-secrets-controller -n kube-system

2022/11/07 04:28:27 Updating catalog/catalog-sealed-db
2022/11/07 04:28:27 Event(v1.ObjectReference{Kind:"SealedSecret", Namespace:"catalog", Name:"catalog-sealed-db", UID:"a2ae3aef-f475-40e9-918c-697cd8cfc67d", APIVersion:"bitnami.com/v1alpha1", ResourceVersion:"23351", FieldPath:""}): type: 'Normal' reason: 'Unsealed' SealedSecret unsealed successfully
```

컨트롤러가 secure-secrets 네임스페이스에 SealedSecret에서 해제된 `catalog-sealed-db` 시크릿을 배포했는지 확인합니다.

```bash
$ kubectl get secret -n catalog catalog-sealed-db

NAME                       TYPE     DATA   AGE
catalog-sealed-db          Opaque   4      7m51s
```

위의 시크릿을 읽는 **catalog** 디플로이먼트를 다시 배포해보겠습니다. `catalog` 디플로이먼트를 다음과 같이 `catalog-sealed-db` 시크릿을 읽도록 업데이트했습니다:

```kustomization
modules/security/sealed-secrets/deployment.yaml
Deployment/catalog
```

```bash
$ kubectl apply -k ~/environment/eks-workshop/modules/security/sealed-secrets
$ kubectl rollout status -n catalog deployment/catalog --timeout 30s
```

SealedSecret 리소스인 **catalog-sealed-db**는 DaemonSet, Deployment, ConfigMap 등과 같은 클러스터에 배포된 다른 Kubernetes 리소스와 관련된 YAML 매니페스트와 함께 Git 저장소에 안전하게 저장할 수 있습니다. 그런 다음 GitOps 워크플로우를 사용하여 이러한 리소스들의 클러스터 배포를 관리할 수 있습니다.