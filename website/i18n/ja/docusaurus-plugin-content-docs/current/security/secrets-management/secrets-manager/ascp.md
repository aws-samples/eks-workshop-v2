---
title: "AWS Secrets and Configuration Provider (ASCP)"
sidebar_position: 422
kiteTranslationSourceHash: ea479b4d3aff83a8f822a98785b759ca
---

[前のステップ](./index.md)で実行した`prepare-environment`スクリプトは、このラボに必要なKubernetes Secrets Store CSIドライバー用のAWS Secrets and Configuration Provider (ASCP)をすでにインストールしています。

アドオンが正しくデプロイされたことを確認しましょう。

まず、Secret Store CSIドライバーの`DaemonSet`とその`Pods`を確認します：

```bash
$ kubectl -n kube-system get pods,daemonsets -l app=secrets-store-csi-driver
NAME                                                        DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR            AGE
daemonset.apps/csi-secrets-store-secrets-store-csi-driver   3         3         3       3            3           kubernetes.io/os=linux   3m57s

NAME                                                   READY   STATUS    RESTARTS   AGE
pod/csi-secrets-store-secrets-store-csi-driver-bzddm   3/3     Running   0          3m57s
pod/csi-secrets-store-secrets-store-csi-driver-k7m6c   3/3     Running   0          3m57s
pod/csi-secrets-store-secrets-store-csi-driver-x2rs4   3/3     Running   0          3m57s
```

次に、AWS用のCSI Secrets Storeプロバイダードライバーの`DaemonSet`とその`Pods`を確認します：

```bash
$ kubectl -n kube-system get pods,daemonset -l "app=secrets-store-csi-driver-provider-aws"
NAME                                                   DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR            AGE
daemonset.apps/secrets-store-csi-driver-provider-aws   3         3         3       3            3           kubernetes.io/os=linux   2m3s

NAME                                              READY   STATUS    RESTARTS   AGE
pod/secrets-store-csi-driver-provider-aws-4jf8f   1/1     Running   0          2m2s
pod/secrets-store-csi-driver-provider-aws-djtf5   1/1     Running   0          2m2s
pod/secrets-store-csi-driver-provider-aws-dzg9r   1/1     Running   0          2m2s
```

CSIドライバーを介してAWS Secrets Managerに保存されているシークレットへのアクセスを提供するには、`SecretProviderClass`が必要です - これはAWS Secrets Managerの情報と一致するドライバー設定とパラメータを提供する名前空間付きのカスタムリソースです。

::yaml{file="manifests/modules/security/secrets-manager/secret-provider-class.yaml" paths="spec.provider,spec.parameters.objects,spec.secretObjects.0"}

1. `provider: aws`はAWS Secrets Store CSIドライバーを指定します
2. `parameters.objects`はAWS `secretsmanager`ソースシークレット名`$SECRET_NAME`を定義し、[jmesPath](https://jmespath.org/)を使用して特定の`username`と`password`フィールドをKubernetesで消費するための名前付きエイリアスとして抽出します
3. `secretObjects`は抽出された`username`と`password`フィールドをシークレットキーにマッピングする標準の`Opaque` Kubernetesシークレット名`catalog-secret`を作成します

このリソースを作成しましょう：

```bash
$ cat ~/environment/eks-workshop/modules/security/secrets-manager/secret-provider-class.yaml \
  | envsubst | kubectl apply -f -
```

Secret Store CSIドライバーはKubernetesとAWS Secrets Managerなどの外部シークレットプロバイダー間の仲介者として機能します。SecretProviderClassで構成すると、Podボリュームのファイルとしてシークレットをマウントし、同期されたKubernetes Secretオブジェクトを作成でき、アプリケーションがこれらのシークレットを消費する方法に柔軟性を提供します。

