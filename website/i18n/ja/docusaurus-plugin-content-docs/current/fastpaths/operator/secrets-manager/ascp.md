---
title: "AWS Secrets and Configuration Provider (ASCP)"
sidebar_position: 422
tmdTranslationSourceHash: 'caf6dfb26db7a75b14bca637027c5da2'
---

このワークショップでは、AWS Secrets and Configuration Provider (ASCP) を EKS クラスターに事前設定しています。

アドオンが正しくデプロイされたことを検証しましょう。

まず、Secret Store CSI driver の `DaemonSet` とその `Pod` を確認します：

```bash
$ kubectl -n kube-system get daemonsets,pods -l app=secrets-store-csi-driver
NAME                                                        DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR            AGE
daemonset.apps/csi-secrets-store-secrets-store-csi-driver   3         3         3       3            3           kubernetes.io/os=linux   3m57s

NAME                                                   READY   STATUS    RESTARTS   AGE
pod/csi-secrets-store-secrets-store-csi-driver-bzddm   3/3     Running   0          3m57s
```

次に、CSI Secrets Store Provider for AWS driver の `DaemonSet` とその `Pod` を確認します：

```bash
$ kubectl -n kube-system get daemonset,pods -l "app=secrets-store-csi-driver-provider-aws"
NAME                                                   DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR            AGE
daemonset.apps/secrets-store-csi-driver-provider-aws   3         3         3       3            3           kubernetes.io/os=linux   2m3s

NAME                                              READY   STATUS    RESTARTS   AGE
pod/secrets-store-csi-driver-provider-aws-4jf8f   1/1     Running   0          2m2s
```

CSI driver を介して AWS Secrets Manager に保存されたシークレットへのアクセスを提供するには、`SecretProviderClass` が必要です。これは、AWS Secrets Manager の情報と一致するドライバー設定とパラメータを提供する namespace スコープの Custom Resource Definition (CRD) です。

::yaml{file="manifests/modules/security/secrets-manager/secret-provider-class.yaml" paths="spec.provider,spec.parameters.objects,spec.secretObjects.0"}

1. `provider: aws` は AWS Secrets Store CSI driver を指定します
2. `parameters.objects` は、`$SECRET_NAME` という名前の AWS `secretsmanager` ソースシークレットを定義し、[jmesPath](https://jmespath.org/) を使用して特定の `username` と `password` フィールドを抽出し、Kubernetes で使用するための名前付きエイリアスに変換します
3. `secretObjects` は、抽出された `username` と `password` フィールドをシークレットキーにマッピングする `catalog-secret` という名前の標準 `Opaque` Kubernetes Secret を作成します

このリソースを作成しましょう：

```bash
$ cat ~/environment/eks-workshop/modules/security/secrets-manager/secret-provider-class.yaml \
  | envsubst | kubectl apply -f -
```

Secret Store CSI Driver は、Kubernetes と AWS Secrets Manager などの外部シークレットプロバイダーの間の仲介役として機能します。SecretProviderClass で設定すると、シークレットを Pod ボリュームのファイルとしてマウントし、同期された Kubernetes Secret オブジェクトを作成することができ、アプリケーションがこれらのシークレットを使用する方法に柔軟性を提供します。

