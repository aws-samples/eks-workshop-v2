---
title: "Kubernetes Pod に AWS Secrets Manager のシークレットをマウントする"
sidebar_position: 423
tmdTranslationSourceHash: '900774bf902b907197a8ccbf7ae6e588'
---

AWS Secrets Manager に保存されたシークレットを Kubernetes Secret と同期したので、それを Pod の中にマウントしてみましょう。まず、`catalog` Deployment と `catalog` Namespace の既存の Secret を確認しましょう。

現在、`catalog` Deployment は環境変数を介して `catalog-db` Secret からデータベース認証情報にアクセスしています:

- `RETAIL_CATALOG_PERSISTENCE_USER`
- `RETAIL_CATALOG_PERSISTENCE_PASSWORD`

これは、`envFrom` で Secret を参照することによって行われます:

```bash
$ kubectl -n catalog get deployment catalog -o yaml | yq '.spec.template.spec.containers[] | .envFrom'

- configMapRef:
    name: catalog
- secretRef:
    name: catalog-db
```

`catalog` Deployment には現在、`/tmp` にマウントされた `emptyDir` 以外に追加の `volumes` や `volumeMounts` はありません:

```bash
$ kubectl -n catalog get deployment catalog -o yaml | yq '.spec.template.spec.volumes'
- emptyDir:
    medium: Memory
  name: tmp-volume
$ kubectl -n catalog get deployment catalog -o yaml | yq '.spec.template.spec.containers[] | .volumeMounts'
- mountPath: /tmp
  name: tmp-volume
```

`catalog` Deployment を変更して、AWS Secrets Manager に保存されたシークレットを認証情報のソースとして使用するようにしましょう:

```kustomization
modules/security/secrets-manager/mounting-secrets/kustomization.yaml
Deployment/catalog
```

以前検証した SecretProviderClass を使用して、CSI ドライバーで AWS Secrets Manager のシークレットを Pod 内の `/etc/catalog-secret` mountPath にマウントします。これにより、AWS Secrets Manager は保存されたシークレットの内容を Amazon EKS と同期し、Pod 内で環境変数として使用できる Kubernetes Secret を作成します。

```bash timeout=180
$ kubectl kustomize ~/environment/eks-workshop/modules/security/secrets-manager/mounting-secrets/ \
  | envsubst | kubectl apply -f-
$ kubectl rollout status -n catalog deployment/catalog --timeout=120s
```

`catalog` Namespace で行われた変更を確認しましょう。

Deployment に新しい `volume` と対応する `volumeMount` が追加され、CSI Secret Store Driver を使用して `/etc/catalog-secret` にマウントされています:

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

マウントされた Secret は、Pod のコンテナファイルシステム内のファイルとして機密情報にアクセスする安全な方法を提供します。このアプローチは、シークレット値を環境変数として公開しないことや、ソース Secret が変更されたときに自動的に更新されることなど、いくつかの利点があります。

Pod 内のマウントされた Secret の内容を確認しましょう:

```bash
$ kubectl -n catalog exec deployment/catalog -- ls /etc/catalog-secret/
eks-workshop-auto-catalog-secret-WDD8yS
password
username
$ kubectl -n catalog exec deployment/catalog -- cat /etc/catalog-secret/${SECRET_NAME} | jq
{"username":"catalog", "password":"dYmNfWV4uEvTzoFu"}
$ kubectl -n catalog exec deployment/catalog -- cat /etc/catalog-secret/username | yq
catalog
$ kubectl -n catalog exec deployment/catalog -- cat /etc/catalog-secret/password | yq
dYmNfWV4uEvTzoFu
```

:::info
CSI ドライバーを使用して AWS Secrets Manager からシークレットをマウントする場合、mountPath に 3 つのファイルが作成されます:

1. AWS シークレットの名前を持つファイルで、完全な JSON 値が含まれます
2. SecretProviderClass で定義された jmesPath 式を介して抽出された各キーの個別のファイル

:::

環境変数は、CSI Secret Store ドライバーを介して SecretProviderClass によって自動的に作成された新しい `catalog-secret` から取得されるようになりました:

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

実行中の Pod で環境変数が正しく設定されていることを確認できます:

```bash
$ kubectl -n catalog exec -ti deployment/catalog -- env | grep PERSISTENCE
RETAIL_CATALOG_PERSISTENCE_ENDPOINT=catalog-mysql:3306
RETAIL_CATALOG_PERSISTENCE_PASSWORD=dYmNfWV4uEvTzoFu
RETAIL_CATALOG_PERSISTENCE_PROVIDER=mysql
RETAIL_CATALOG_PERSISTENCE_DB_NAME=catalog
RETAIL_CATALOG_PERSISTENCE_USER=catalog
```

これで、シークレット管理のベストプラクティスであるシークレットローテーションを活用できる、AWS Secrets Manager と完全に統合された Kubernetes Secret ができました。AWS Secrets Manager でシークレットがローテーションまたは更新されたときは、Deployment の新しいバージョンをロールアウトすることで、CSI Secret Store ドライバーが Kubernetes Secret の内容を更新された値と同期できるようになります。

