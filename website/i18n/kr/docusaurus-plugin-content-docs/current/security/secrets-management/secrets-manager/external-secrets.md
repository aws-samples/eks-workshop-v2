---
title: "External Secrets Operator"
sidebar_position: 424
---

이제 External Secrets 오퍼레이터를 사용하여 AWS Secrets Manager와의 통합을 살펴보겠습니다. 이는 이미 우리의 EKS 클러스터에 설치되어 있습니다:

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

이 오퍼레이터는 [IRSA](../../iam-roles-for-service-accounts/)를 통해 IAM 역할과 연결된 `external-secrets-sa`라는 ServiceAccount를 사용하여 AWS Secrets Manager에서 시크릿을 검색할 수 있는 접근 권한을 제공합니다:

```bash
$ kubectl -n external-secrets describe sa external-secrets-sa | grep Annotations
Annotations:         eks.amazonaws.com/role-arn: arn:aws:iam::1234567890:role/eks-workshop-external-secrets-sa-irsa
```

`ClusterSecretStore` 리소스를 생성해야 합니다 - 이는 모든 네임스페이스의 ExternalSecrets에서 참조할 수 있는 클러스터 전체 SecretStore입니다:

```file
manifests/modules/security/secrets-manager/cluster-secret-store.yaml
```

```bash
$ cat ~/environment/eks-workshop/modules/security/secrets-manager/cluster-secret-store.yaml \
  | envsubst | kubectl apply -f -
```

새로 생성된 이 리소스의 사양을 살펴보겠습니다:

```bash
$ kubectl get clustersecretstores.external-secrets.io
NAME                   AGE   STATUS   CAPABILITIES   READY
cluster-secret-store   81s   Valid    ReadWrite      True
$ kubectl get clustersecretstores.external-secrets.io cluster-secret-store  -o yaml | yq '.spec'
provider:
  aws:
    auth:
      jwt:
        serviceAccountRef:
          name: external-secrets-sa
          namespace: external-secrets
    region: us-west-2
    service: SecretsManager

```

ClusterSecretStore는 [JSON Web Token (JWT)](https://jwt.io/)을 사용하여 우리의 ServiceAccount를 참조하고 AWS Secrets Manager와 인증합니다.

다음으로, AWS Secrets Manager에서 어떤 데이터를 가져와야 하고 이를 어떻게 Kubernetes Secret으로 변환해야 하는지 정의하는 `ExternalSecret`을 생성하겠습니다. 그런 다음 이 자격 증명을 사용하도록 `catalog` Deployment를 업데이트할 것입니다:

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

`SecretSynced` 상태는 AWS Secrets Manager로부터의 성공적인 동기화를 나타냅니다. 리소스 사양을 살펴보겠습니다:

```bash
$ kubectl -n catalog get externalsecrets.external-secrets.io catalog-external-secret -o yaml | yq '.spec'
dataFrom:
  - extract:
      conversionStrategy: Default
      decodingStrategy: None
      key: eks-workshop/catalog-secret
refreshInterval: 1h
secretStoreRef:
  kind: ClusterSecretStore
  name: cluster-secret-store
target:
  creationPolicy: Owner
  deletionPolicy: Retain
```

구성은 `key` 매개변수와 이전에 생성한 `ClusterSecretStore`를 통해 AWS Secrets Manager 시크릿을 참조합니다. 1시간의 `refreshInterval`은 시크릿 값이 얼마나 자주 동기화되는지 결정합니다.

ExternalSecret을 생성하면 자동으로 해당하는 Kubernetes 시크릿이 생성됩니다:

```bash
$ kubectl -n catalog get secrets
NAME                      TYPE     DATA   AGE
catalog-db                Opaque   2      21h
catalog-external-secret   Opaque   2      1m
catalog-secret            Opaque   2      5h40m
```

이 시크릿은 External Secrets Operator가 소유합니다:

```bash
$ kubectl -n catalog get secret catalog-external-secret -o yaml | yq '.metadata.ownerReferences'
- apiVersion: external-secrets.io/v1beta1
  blockOwnerDeletion: true
  controller: true
  kind: ExternalSecret
  name: catalog-external-secret
  uid: b8710001-366c-44c2-8e8d-462d85b1b8d7
```

`catalog` 파드가 새로운 시크릿 값을 사용하고 있는지 확인할 수 있습니다:

```bash
$ kubectl -n catalog get pods
NAME                       READY   STATUS    RESTARTS   AGE
catalog-777c4d5dc8-lmf6v   1/1     Running   0          1m
catalog-mysql-0            1/1     Running   0          24h
$ kubectl -n catalog get deployment catalog -o yaml | yq '.spec.template.spec.containers[] | .env'
- name: DB_USER
  valueFrom:
    secretKeyRef:
      key: username
      name: catalog-external-secret
- name: DB_PASSWORD
  valueFrom:
    secretKeyRef:
      key: password
      name: catalog-external-secret
```

### 결론

**AWS Secrets and Configuration Provider (ASCP)**와 **External Secrets Operator (ESO)** 중에서 AWS Secrets Manager 시크릿을 관리하는 데 있어 단일 "최선의" 선택은 없습니다.

각 도구는 고유한 장점이 있습니다. ASCP는 AWS Secrets Manager의 시크릿을 볼륨으로 직접 마운트할 수 있어 환경 변수로의 노출을 피할 수 있지만, 볼륨 관리가 필요합니다. ESO는 Kubernetes Secrets 수명 주기 관리를 단순화하고 클러스터 전체 SecretStore 기능을 제공하지만, 볼륨 마운트를 지원하지 않습니다. 특정 사용 사례에 따라 결정을 내려야 하며, 두 도구를 모두 사용하면 시크릿 관리에서 최대한의 유연성과 보안을 제공할 수 있습니다.