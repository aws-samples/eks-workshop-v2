---
title: "External Secrets Operator"
sidebar_position: 424
tmdTranslationSourceHash: a83e79135004db35c75e04bc4266b948
---

이제 External Secrets operator를 사용하여 AWS Secrets Manager와 통합하는 방법을 살펴보겠습니다. 이는 이미 EKS 클러스터에 설치되어 있습니다:

```bash
$ kubectl -n external-secrets get pods
NAME                                                READY   STATUS    RESTARTS   AGE
external-secrets-6d95d66dc8-5trlv                   1/1     Running   0          7m
external-secrets-cert-controller-774dff987b-krnp7   1/1     Running   0          7m
external-secrets-webhook-6565844f8f-jxst8           1/1     Running   0          7m
$ kubectl -n external-secrets get sa
NAME                  SECRETS   AGE
default               0         7m
external-secrets-sa   0         7m
```

operator는 `external-secrets-sa`라는 이름의 ServiceAccount를 사용하며, [IRSA](../../iam-roles-for-service-accounts/)를 통해 IAM role과 연결되어 Secret을 검색하기 위한 AWS Secrets Manager 액세스 권한을 제공합니다:

```bash
$ kubectl -n external-secrets describe sa external-secrets-sa | grep Annotations
Annotations:         eks.amazonaws.com/role-arn: arn:aws:iam::1234567890:role/eks-workshop-external-secrets-sa-irsa
```

`ClusterSecretStore` 리소스를 생성해야 합니다. 이는 모든 네임스페이스의 ExternalSecrets에서 참조할 수 있는 클러스터 전체 SecretStore입니다. 이 `ClusterSecretStore`를 생성하는 데 사용할 파일을 살펴보겠습니다:

::yaml{file="manifests/modules/security/secrets-manager/cluster-secret-store.yaml" paths="spec.provider.aws.service,spec.provider.aws.region,spec.provider.aws.auth.jwt"}

1. `service: SecretsManager`를 설정하여 AWS Secrets Manager를 Secret 소스로 사용합니다
2. `$AWS_REGION` 환경 변수를 사용하여 Secret이 저장된 AWS 리전을 지정합니다
3. `auth.jwt`는 IRSA를 사용하여 `external-secrets` 네임스페이스의 `external-secrets-sa` service account를 통해 인증하며, 이는 AWS Secrets Manager 권한이 있는 IAM role과 연결되어 있습니다

이 파일을 사용하여 ClusterSecretStore 리소스를 생성하겠습니다.

```bash
$ cat ~/environment/eks-workshop/modules/security/secrets-manager/cluster-secret-store.yaml \
  | envsubst | kubectl apply -f -
```

다음으로, AWS Secrets Manager에서 가져올 데이터와 Kubernetes Secret으로 변환하는 방법을 정의하는 `ExternalSecret`을 생성합니다. 그런 다음 이러한 자격 증명을 사용하도록 `catalog` Deployment를 업데이트합니다:

```kustomization
modules/security/secrets-manager/external-secrets/kustomization.yaml
Deployment/catalog
ExternalSecret/catalog-external-secret
```

```bash
$ kubectl kustomize ~/environment/eks-workshop/modules/security/secrets-manager/external-secrets/ \
  | envsubst | kubectl apply -f-
$ kubectl rollout status -n catalog deployment/catalog --timeout=120s
```

새로운 `ExternalSecret` 리소스를 살펴보겠습니다:

```bash
$ kubectl -n catalog get externalsecrets.external-secrets.io
NAME                      STORE                  REFRESH INTERVAL   STATUS         READY
catalog-external-secret   cluster-secret-store   1h                 SecretSynced   True
```

`SecretSynced` 상태는 AWS Secrets Manager에서 성공적으로 동기화되었음을 나타냅니다. 리소스 사양을 살펴보겠습니다:

```bash
$ kubectl -n catalog get externalsecrets.external-secrets.io catalog-external-secret -o yaml | yq '.spec'
dataFrom:
  - extract:
      conversionStrategy: Default
      decodingStrategy: None
      key: eks-workshop-catalog-secret-WDD8yS
refreshInterval: 1h
secretStoreRef:
  kind: ClusterSecretStore
  name: cluster-secret-store
target:
  creationPolicy: Owner
  deletionPolicy: Retain
```

구성은 `key` 파라미터를 통해 AWS Secrets Manager secret을 참조하고 앞서 생성한 `ClusterSecretStore`를 참조합니다. 1시간의 `refreshInterval`은 Secret 값이 동기화되는 빈도를 결정합니다.

ExternalSecret을 생성하면 해당 Kubernetes secret이 자동으로 생성됩니다:

```bash
$ kubectl -n catalog get secrets
NAME                      TYPE     DATA   AGE
catalog-db                Opaque   2      21h
catalog-external-secret   Opaque   2      1m
catalog-secret            Opaque   2      5h40m
```

이 Secret은 External Secrets Operator가 소유합니다:

```bash
$ kubectl -n catalog get secret catalog-external-secret -o yaml | yq '.metadata.ownerReferences'
- apiVersion: external-secrets.io/v1beta1
  blockOwnerDeletion: true
  controller: true
  kind: ExternalSecret
  name: catalog-external-secret
  uid: b8710001-366c-44c2-8e8d-462d85b1b8d7
```

`catalog` Pod가 새 Secret 값을 사용하고 있는지 확인할 수 있습니다:

```bash
$ kubectl -n catalog get pods
NAME                       READY   STATUS    RESTARTS   AGE
catalog-777c4d5dc8-lmf6v   1/1     Running   0          1m
catalog-mysql-0            1/1     Running   0          24h
$ kubectl -n catalog get deployment catalog -o yaml | yq '.spec.template.spec.containers[] | .env'
- name: RETAIL_CATALOG_PERSISTENCE_USER
  valueFrom:
    secretKeyRef:
      key: username
      name: catalog-external-secret
- name: RETAIL_CATALOG_PERSISTENCE_PASSWORD
  valueFrom:
    secretKeyRef:
      key: password
      name: catalog-external-secret
```

### 결론

AWS Secrets Manager Secret을 관리하기 위한 **AWS Secrets and Configuration Provider (ASCP)**와 **External Secrets Operator (ESO)** 중 단일 "최선의" 선택은 없습니다.

각 도구에는 고유한 장점이 있습니다:

- **ASCP**는 AWS Secrets Manager에서 직접 볼륨으로 Secret을 마운트할 수 있어 환경 변수로 노출되는 것을 방지할 수 있지만, 볼륨 관리가 필요합니다.

- **ESO**는 Kubernetes Secrets 라이프사이클 관리를 단순화하고 클러스터 전체 SecretStore 기능을 제공하지만, 볼륨 마운트를 지원하지 않습니다.

특정 사용 사례에 따라 결정해야 하며, 두 도구를 모두 사용하면 Secret 관리에서 최대한의 유연성과 보안을 제공할 수 있습니다.

