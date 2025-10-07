---
title: "Sealed Secretsをインストールする"
sidebar_position: 432
kiteTranslationSourceHash: 246ad1cfd01b66427b3cb86d7aa5badf
---

`kubeseal` CLIはシールドシークレットコントローラとやり取りするために使用され、あなたのIDE内にすでにインストールされています。

最初に行うことは、EKSクラスターにシールドシークレットコントローラをインストールすることです：

```bash
$ kubectl apply -f https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.18.0/controller.yaml
$ kubectl wait --for=condition=Ready --timeout=30s \
  pods -l name=sealed-secrets-controller -n kube-system
```

次にポッドのステータスを確認します

```bash
$ kubectl get pods -n kube-system -l name=sealed-secrets-controller
sealed-secrets-controller-77747c4b8c-snsxp      1/1     Running   0          5s
```

シールドシークレットコントローラのログには、起動時に既存のプライベートキーを探そうとしていることが示されています。プライベートキーが見つからない場合は、証明書の詳細を含む新しいシークレットを作成します。

```bash
$ kubectl logs deployments/sealed-secrets-controller -n kube-system
controller version: 0.18.0
2022/10/18 09:17:01 Starting sealed-secrets controller version: 0.18.0
2022/10/18 09:17:01 Searching for existing private keys
2022/10/18 09:17:02 New key written to kube-system/sealed-secrets-keyvkl9w
2022/10/18 09:17:02 Certificate is
-----BEGIN CERTIFICATE-----
MIIEzTCCArWgAwIBAgIRAPsk+UrW9GlPu4gXN1qKqGswDQYJKoZIhvcNAQELBQAw
ADAeFw0yMjEwMTgwOTE3MDJaFw0zMjEwMTUwOTE3MDJaMAAwggIiMA0GCSqGSIb3
(...)
q5P11EvxPBfIt9xDx5Jz4JWp5M7wWawGaeBqTmTDbSkc
-----END CERTIFICATE-----

2022/10/18 09:17:02 HTTP server serving on :8080
```

YAML形式のパブリック/プライベートキーペアとしてシーリングキーを含むSecretの内容は次のように確認できます：

```bash
$ kubectl get secret -n kube-system \
  -l sealedsecrets.bitnami.com/sealed-secrets-key -o yaml
apiVersion: v1
items:
- apiVersion: v1
  data:
    tls.crt: LS0tL(...)LQo=
    tls.key: LS0tL(...)LS0K
  kind: Secret
  metadata:
    creationTimestamp: "2022-10-18T09:17:02Z"
    generateName: sealed-secrets-key
    labels:
      sealedsecrets.bitnami.com/sealed-secrets-key: active
    name: sealed-secrets-keyvkl9w
    namespace: kube-system
    resourceVersion: "129381"
    uid: 23f5e70c-2537-4c38-a85c-b410f1dcf9a6
  type: kubernetes.io/tls
kind: List
metadata:
  resourceVersion: ""
  selfLink: ""
```
