---
title: "External Secrets Operator"
sidebar_position: 424
kiteTranslationSourceHash: a83e79135004db35c75e04bc4266b948
---

次に、External Secrets operatorを使用したAWS Secrets Managerとの統合を探ってみましょう。これは既にEKSクラスタにインストールされています：

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

オペレーターは`external-secrets-sa`という名前のServiceAccountを使用しており、これは[IRSA](../../iam-roles-for-service-accounts/)を介してIAMロールに関連付けられ、AWS Secrets Managerへのアクセス権を提供しています：

```bash
$ kubectl -n external-secrets describe sa external-secrets-sa | grep Annotations
Annotations:         eks.amazonaws.com/role-arn: arn:aws:iam::1234567890:role/eks-workshop-external-secrets-sa-irsa
```

`ClusterSecretStore`リソースを作成する必要があります - これは任意の名前空間からExternalSecretsが参照できるクラスター全体のSecretStoreです。この`ClusterSecretStore`を作成するために使用するファイルを確認してみましょう：

::yaml{file="manifests/modules/security/secrets-manager/cluster-secret-store.yaml" paths="spec.provider.aws.service,spec.provider.aws.region,spec.provider.aws.auth.jwt"}

1. シークレットソースとしてAWS Secrets Managerを使用するために`service: SecretsManager`を設定
2. シークレットが保存されているAWSリージョンを指定するために`$AWS_REGION`環境変数を使用
3. `auth.jwt`はIRSAを使用して`external-secrets`名前空間の`external-secrets-sa`サービスアカウントで認証し、これはAWS Secrets Managerへのアクセス権を持つIAMロールにリンクされています

このファイルを使用してClusterSecretStoreリソースを作成しましょう。

```bash
$ cat ~/environment/eks-workshop/modules/security/secrets-manager/cluster-secret-store.yaml \
  | envsubst | kubectl apply -f -
```

次に、AWS Secrets Managerからどのデータを取得し、それをKubernetesシークレットにどのように変換するかを定義する`ExternalSecret`を作成します。その後、これらの認証情報を使用するように`catalog`デプロイメントを更新します：

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

新しい`ExternalSecret`リソースを確認してみましょう：

```bash
$ kubectl -n catalog get externalsecrets.external-secrets.io
NAME                      STORE                  REFRESH INTERVAL   STATUS         READY
catalog-external-secret   cluster-secret-store   1h                 SecretSynced   True
```

`SecretSynced`ステータスはAWS Secrets Managerからの同期が成功したことを示しています。リソースの仕様を見てみましょう：

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

この設定は、`key`パラメータと先ほど作成した`ClusterSecretStore`を通じてAWS Secrets Managerのシークレットを参照しています。1時間の`refreshInterval`は、シークレット値がどの頻度で同期されるかを決定します。

ExternalSecretを作成すると、自動的に対応するKubernetesシークレットが作成されます：

```bash
$ kubectl -n catalog get secrets
NAME                      TYPE     DATA   AGE
catalog-db                Opaque   2      21h
catalog-external-secret   Opaque   2      1m
catalog-secret            Opaque   2      5h40m
```

このシークレットはExternal Secrets Operatorによって所有されています：

```bash
$ kubectl -n catalog get secret catalog-external-secret -o yaml | yq '.metadata.ownerReferences'
- apiVersion: external-secrets.io/v1beta1
  blockOwnerDeletion: true
  controller: true
  kind: ExternalSecret
  name: catalog-external-secret
  uid: b8710001-366c-44c2-8e8d-462d85b1b8d7
```

私たちの`catalog`ポッドが新しいシークレット値を使用していることを確認できます：

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

**AWS Secrets and Configuration Provider（ASCP）**と**External Secrets Operator（ESO）**の間には、AWS Secrets Managerのシークレットを管理するための「最良」な選択肢はありません。

それぞれのツールには異なる利点があります：

- **ASCP**はAWS Secrets Managerからシークレットを直接ボリュームとしてマウントでき、環境変数として公開されることを避けることができますが、ボリューム管理が必要です。

- **ESO**はKubernetesシークレットのライフサイクル管理を簡素化し、クラスター全体のSecretStore機能を提供しますが、ボリュームマウントはサポートしていません。

あなたの具体的なユースケースに基づいて決定すべきであり、両方のツールを使用することでシークレット管理における最大限の柔軟性とセキュリティを提供することができます。
