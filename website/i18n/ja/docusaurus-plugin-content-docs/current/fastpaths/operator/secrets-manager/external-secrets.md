---
title: "External Secrets Operator"
sidebar_position: 424
tmdTranslationSourceHash: '1de17192c2e07a824ef9d3b122a721db'
---

次に、External Secrets Operator を使用して AWS Secrets Manager と統合する方法を見ていきましょう。これは既に EKS クラスターにインストールされています:

```bash wait=30
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

Operator は `external-secrets-sa` という名前の ServiceAccount を使用しており、これは [EKS Pod Identities](../amazon-eks-pod-identity/) を介して IAM role に関連付けられ、シークレットを取得するために AWS Secrets Manager へのアクセスを提供します:

`ClusterSecretStore` リソースを作成する必要があります - これは、任意の namespace の ExternalSecrets から参照できるクラスター全体の SecretStore です。この `ClusterSecretStore` を作成するために使用するファイルを見てみましょう:

::yaml{file="manifests/modules/fastpaths/operators/external-secrets/cluster-secret-store.yaml" paths="spec.provider.aws.service,spec.provider.aws.region"}

1. シークレットソースとして AWS Secrets Manager を使用するために `service: SecretsManager` を設定
2. `$AWS_REGION` 環境変数を使用して、シークレットが保存されている AWS リージョンを指定

:::note
EKS Pod Identites を使用する場合、ServiceAccount `external-secrets-sa` を AWS Secrets Manager 権限を持つ IAM role にリンクする Pod Identity Association を介して認証するため、ここで auth セクションは不要です
:::

このファイルを使用して ClusterSecretStore リソースを作成しましょう。

```bash timeout=300
$ kubectl wait --for=condition=available deployment/external-secrets-webhook -n external-secrets --timeout=240s
$ cat ~/environment/eks-workshop/modules/fastpaths/operators/external-secrets/cluster-secret-store.yaml \
  | envsubst | kubectl apply -f -
```

次に、AWS Secrets Manager から取得するデータと、それを Kubernetes Secret に変換する方法を定義する `ExternalSecret` を作成します。その後、これらの認証情報を使用するように `catalog` Deployment を更新します:

```kustomization
modules/security/secrets-manager/external-secrets/kustomization.yaml
Deployment/catalog
ExternalSecret/catalog-external-secret
```

```bash timeout=180
$ kubectl kustomize ~/environment/eks-workshop/modules/security/secrets-manager/external-secrets/ \
  | envsubst | kubectl apply -f-
$ kubectl rollout status -n catalog deployment/catalog --timeout=120s
```

新しい `ExternalSecret` リソースを見てみましょう:

```bash
$ kubectl -n catalog get externalsecrets.external-secrets.io
NAME                      STORE                  REFRESH INTERVAL   STATUS         READY
catalog-external-secret   cluster-secret-store   1h                 SecretSynced   True
```

`SecretSynced` ステータスは、AWS Secrets Manager からの同期が成功したことを示しています。リソースの仕様を見てみましょう:

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

この設定は、`key` パラメータを介して AWS Secrets Manager のシークレットと、先ほど作成した `ClusterSecretStore` を参照しています。1 時間の `refreshInterval` は、シークレット値が同期される頻度を決定します。

ExternalSecret を作成すると、対応する Kubernetes secret が自動的に作成されます:

```bash
$ kubectl -n catalog get secrets
NAME                      TYPE     DATA   AGE
catalog-db                Opaque   2      21h
catalog-external-secret   Opaque   2      1m
catalog-secret            Opaque   2      5h40m
```

このシークレットは External Secrets Operator によって所有されています:

```bash
$ kubectl -n catalog get secret catalog-external-secret -o yaml | yq '.metadata.ownerReferences'
- apiVersion: external-secrets.io/v1beta1
  blockOwnerDeletion: true
  controller: true
  kind: ExternalSecret
  name: catalog-external-secret
  uid: b8710001-366c-44c2-8e8d-462d85b1b8d7
```

`catalog` Pod が新しいシークレット値を使用していることを確認できます:

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

### まとめ

AWS Secrets Manager のシークレットを管理するための **AWS Secrets and Configuration Provider (ASCP)** と **External Secrets Operator (ESO)** の間に、単一の「ベスト」な選択肢はありません。

各ツールには明確な利点があります:

- **ASCP** は、環境変数としての露出を避けて、AWS Secrets Manager からシークレットを volume として直接マウントできますが、これには volume 管理が必要です。

- **ESO** は Kubernetes Secrets のライフサイクル管理を簡素化し、クラスター全体の SecretStore 機能を提供しますが、volume マウントをサポートしていません。

特定のユースケースが意思決定を主導すべきであり、両方のツールを使用することで、シークレット管理において最大限の柔軟性とセキュリティを提供できます。

