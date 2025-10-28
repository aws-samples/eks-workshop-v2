---
title: "シークレットのシール"
sidebar_position: 433
kiteTranslationSourceHash: 0d58a7c004d07480c7b8c02ef63cf83c
---

### カタログPodの探索

現在、`catalog`デプロイメントは、環境変数を通じて`catalog-db`シークレットからデータベース認証情報にアクセスしています：

- `RETAIL_CATALOG_PERSISTENCE_USER`
- `RETAIL_CATALOG_PERSISTENCE_PASSWORD`

これは`envFrom`を使用してシークレットを参照することで行われています：

```bash
$ kubectl -n catalog get deployment catalog -o yaml | yq '.spec.template.spec.containers[] | .envFrom'

- configMapRef:
    name: catalog
- secretRef:
    name: catalog-db
```

`catalog-db`シークレットを調査すると、base64エンコードされただけであることがわかります。これは以下のように簡単にデコードできるため、シークレットマニフェストをGitOpsワークフローの一部とすることが難しくなります。

```file
manifests/base-application/catalog/secrets.yaml
```

```bash
$ kubectl -n catalog get secrets catalog-db --template {{.data.RETAIL_CATALOG_PERSISTENCE_USER}} | base64 -d
catalog%
$ kubectl -n catalog get secrets catalog-db --template {{.data.RETAIL_CATALOG_PERSISTENCE_PASSWORD}} | base64 -d
dYmNfWV4uEvTzoFu%
```

`catalog-sealed-db`という新しいシークレットを作成しましょう。`catalog-db`シークレットと同じキーと値を持つ新しいファイル`new-catalog-db.yaml`を作成します。

```file
manifests/modules/security/sealed-secrets/new-catalog-db.yaml
```

次に、kubesealを使用してSealedSecret YAMLマニフェストを作成します。

```bash
$ kubeseal --format=yaml < ~/environment/eks-workshop/modules/security/sealed-secrets/new-catalog-db.yaml \
  > /tmp/sealed-catalog-db.yaml
```

または、コントローラから公開鍵を取得し、オフラインでシークレットをシールすることもできます：

```bash test=false
$ kubeseal --fetch-cert > /tmp/public-key-cert.pem
$ kubeseal --cert=/tmp/public-key-cert.pem --format=yaml < ~/environment/eks-workshop/modules/security/sealed-secrets/new-catalog-db.yaml \
  > /tmp/sealed-catalog-db.yaml
```

これにより、以下の内容のsealed-secretが作成されます：

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

SealedSecretをEKSクラスタにデプロイしましょう：

```bash
$ kubectl apply -f /tmp/sealed-catalog-db.yaml
```

コントローラのログを見ると、デプロイされたSealedSecretカスタムリソースを検知し、それを解除して通常のシークレットを作成していることがわかります。

```bash
$ kubectl logs deployments/sealed-secrets-controller -n kube-system

2022/11/07 04:28:27 Updating catalog/catalog-sealed-db
2022/11/07 04:28:27 Event(v1.ObjectReference{Kind:"SealedSecret", Namespace:"catalog", Name:"catalog-sealed-db", UID:"a2ae3aef-f475-40e9-918c-697cd8cfc67d", APIVersion:"bitnami.com/v1alpha1", ResourceVersion:"23351", FieldPath:""}): type: 'Normal' reason: 'Unsealed' SealedSecret unsealed successfully
```

コントローラによってSealedSecretから解除された`catalog-sealed-db`シークレットがsecure-secretsネームスペースにデプロイされたことを確認します。

```bash
$ kubectl get secret -n catalog catalog-sealed-db

NAME                       TYPE     DATA   AGE
catalog-sealed-db          Opaque   4      7m51s
```

上記のシークレットから読み取る**catalog**デプロイメントを再デプロイしましょう。`catalog`デプロイメントを更新して、`catalog-sealed-db`シークレットを読み取るようにしました：

```kustomization
modules/security/sealed-secrets/deployment.yaml
Deployment/catalog
```

```bash
$ kubectl apply -k ~/environment/eks-workshop/modules/security/sealed-secrets
$ kubectl rollout status -n catalog deployment/catalog --timeout 30s
```

SealedSecretリソースである**catalog-sealed-db**は、クラスターにデプロイされた他のKubernetesリソース（DaemonSet、Deployment、ConfigMapなど）に関するYAMLマニフェストとともにGitリポジトリに安全に保存できます。その後、GitOpsワークフローを使用して、これらのリソースをクラスターにデプロイする管理ができます。

