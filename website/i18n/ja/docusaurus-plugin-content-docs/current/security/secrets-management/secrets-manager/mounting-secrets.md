---
title: "AWS Secrets Manager のシークレットを Kubernetes Pod にマウントする"
sidebar_position: 423
tmdTranslationSourceHash: 0b07d0bd4408ba68fee8d10501569a50
---

AWS Secrets Manager のシークレットを保存し、Kubernetes のシークレットと同期したので、そのシークレットを Pod の中にマウントしてみましょう。まず、`catalog` デプロイメントと `catalog` 名前空間に存在するシークレットを確認しましょう。

現在、`catalog` デプロイメントは、環境変数を通じて `catalog-db` シークレットからデータベースの認証情報にアクセスしています：

- `RETAIL_CATALOG_PERSISTENCE_USER`
- `RETAIL_CATALOG_PERSISTENCE_PASSWORD`

これは、`envFrom` を使用してシークレットを参照することで行われています：

```bash
$ kubectl -n catalog get deployment catalog -o yaml | yq '.spec.template.spec.containers[] | .envFrom'

- configMapRef:
    name: catalog
- secretRef:
    name: catalog-db
```

`catalog` デプロイメントには現在、`/tmp` にマウントされている `emptyDir` 以外の追加の `volumes` や `volumeMounts` はありません：

```bash
$ kubectl -n catalog get deployment catalog -o yaml | yq '.spec.template.spec.volumes'
- emptyDir:
    medium: Memory
  name: tmp-volume
$ kubectl -n catalog get deployment catalog -o yaml | yq '.spec.template.spec.containers[] | .volumeMounts'
- mountPath: /tmp
  name: tmp-volume
```

AWS Secrets Manager に保存されているシークレットを認証情報のソースとして使用するように `catalog` デプロイメントを変更しましょう：

```kustomization
modules/security/secrets-manager/mounting-secrets/kustomization.yaml
Deployment/catalog
```

CSI ドライバーを使用して AWS Secrets Manager シークレットをマウントし、以前に検証した SecretProviderClass を使用して、Pod 内の `/etc/catalog-secret` マウントパスにマウントします。これにより、AWS Secrets Manager は保存されたシークレットの内容を Amazon EKS と同期し、Pod 内で環境変数として消費できる Kubernetes シークレットを作成します。

```bash
$ kubectl kustomize ~/environment/eks-workshop/modules/security/secrets-manager/mounting-secrets/ \
  | envsubst | kubectl apply -f-
$ kubectl rollout status -n catalog deployment/catalog --timeout=120s
```

`catalog` 名前空間で行われた変更を確認しましょう。

デプロイメントには、CSI Secret Store ドライバーを使用する新しい `volume` と対応する `volumeMount` が追加され、`/etc/catalog-secret` にマウントされています：

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

マウントされたシークレットは、Pod のコンテナファイルシステム内にファイルとして機密情報にアクセスする安全な方法を提供します。このアプローチには、環境変数としてシークレット値を公開しないことや、ソースシークレットが変更されたときに自動更新されるなど、いくつかの利点があります。

Pod 内部でマウントされたシークレットの内容を調べてみましょう：

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
CSI ドライバーを使用して AWS Secrets Manager からシークレットをマウントすると、マウントパスに 3 つのファイルが作成されます：

1. AWS シークレットの名前を持つファイルで、完全な JSON 値が含まれます
2. SecretProviderClass で定義された jmesPath 式を通じて抽出された各キーの個別ファイル
   :::

環境変数は、CSI Secret Store ドライバーを介して SecretProviderClass によって自動的に作成された `catalog-secret` から取得されるようになりました：

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

実行中の Pod で環境変数が正しく設定されていることを確認できます：

```bash
$ kubectl -n catalog exec -ti deployment/catalog -- env | grep PERSISTENCE
RETAIL_CATALOG_PERSISTENCE_ENDPOINT=catalog-mysql:3306
RETAIL_CATALOG_PERSISTENCE_PASSWORD=dYmNfWV4uEvTzoFu
RETAIL_CATALOG_PERSISTENCE_PROVIDER=mysql
RETAIL_CATALOG_PERSISTENCE_DB_NAME=catalog
RETAIL_CATALOG_PERSISTENCE_USER=catalog
```

これで AWS Secrets Manager と完全に統合された Kubernetes シークレットがあり、シークレット管理のベストプラクティスであるシークレットのローテーションを活用できます。AWS Secrets Manager でシークレットがローテーションまたは更新されると、デプロイメントの新しいバージョンをロールアウトして、CSI Secret Store ドライバーが Kubernetes シークレットの内容を更新された値と同期できるようにすることができます。
