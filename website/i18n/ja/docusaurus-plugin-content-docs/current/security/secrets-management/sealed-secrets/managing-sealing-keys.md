---
title: "シーリングキーの管理"
sidebar_position: 434
tmdTranslationSourceHash: a072117fa3ec03e6c678452d1cc60a39
---

SealedSecret内の暗号化データを復号する唯一の方法は、コントローラーが管理するシーリングキーを使用することです。災害後にクラスターの元の状態を復元しようとする場合や、GitOpsワークフローを活用してSealedSecretを含むKubernetesリソースをGitリポジトリからデプロイし、新しいEKSクラスターを作成したい場合など、様々な状況が考えられます。新しいEKSクラスターにデプロイされたコントローラーは、SealedSecretsを復号できるよう同じシーリングキーを使用する必要があります。

次のコマンドを実行して、クラスターからシーリングキーを取得します。本番環境では、この操作を実行するために必要な権限を制限されたクライアントセットに付与するために、Kubernetes RBACを活用することがベストプラクティスとされています。

```bash
$ kubectl get secret -n kube-system -l sealedsecrets.bitnami.com/sealed-secrets-key -o yaml \
  > /tmp/master-sealing-key.yaml
```

操作をテストするために、シーリングキーを含むSecretを削除し、シールドシークレットコントローラーを再起動してみましょう：

```bash
$ kubectl delete secret -n kube-system -l sealedsecrets.bitnami.com/sealed-secrets-key
$ kubectl -n kube-system delete pod -l name=sealed-secrets-controller
$ kubectl wait --for=condition=Ready --timeout=30s pods -l name=sealed-secrets-controller -n kube-system
```

次に、コントローラーのログを確認します。SealedSecretの復号に失敗していることがわかります：

```bash
$ kubectl logs deployment/sealed-secrets-controller -n kube-system
[...]
2022/11/18 22:47:42 Updating catalog/catalog-sealed-db
2022/11/18 22:47:43 Error updating catalog/catalog-sealed-db, giving up: no key could decrypt secret (password, username, endpoint, name)
E1118 22:47:43.030178       1 controller.go:175] no key could decrypt secret (password, username, endpoint, name)
2022/11/18 22:47:43 Event(v1.ObjectReference{Kind:"SealedSecret", Namespace:"catalog", Name:"catalog-sealed-db", UID:"a6705e6f-72a1-43f5-8c0b-4f45b9b6f5fb", APIVersion:"bitnami.com/v1alpha1", ResourceVersion:"519192", FieldPath:""}): type: 'Warning' reason: 'ErrUnsealFailed' Failed to unseal: no key could decrypt secret (password, username, endpoint, name)
```

これは、シーリングキーを削除したことにより、コントローラが起動時に新しいキーを生成したためです。これにより、すべてのSealedSecretリソースがこのコントローラからアクセスできなくなりました。ありがたいことに、以前に`/tmp/master-sealing-key.yaml`に保存したので、EKSクラスターに再作成することができます：

```bash
$ kubectl apply -f /tmp/master-sealing-key.yaml
$ kubectl -n kube-system delete pod -l name=sealed-secrets-controller
$ kubectl wait --for=condition=Ready --timeout=30s pods -l name=sealed-secrets-controller -n kube-system
```

ログを再度確認すると、今回はコントローラーが復元したシーリングキーを拾って、`catalog-sealed-db`シークレットを復号化したことがわかります：

```bash
$ kubectl logs deployment/sealed-secrets-controller -n kube-system
[...]
2022/11/18 22:52:51 Updating catalog/catalog-sealed-db
2022/11/18 22:52:51 Event(v1.ObjectReference{Kind:"SealedSecret", Namespace:"catalog", Name:"catalog-sealed-db", UID:"a6705e6f-72a1-43f5-8c0b-4f45b9b6f5fb", APIVersion:"bitnami.com/v1alpha1", ResourceVersion:"519192", FieldPath:""}): type: 'Normal' reason: 'Unsealed' SealedSecret unsealed successfully
```

`/tmp/master-sealing-key.yaml`ファイルには、コントローラによって生成された公開/秘密キーペアが含まれています。このファイルが漏洩すると、すべてのSealedSecretマニフェストが復号され、保存されている暗号化された機密情報が明らかになる可能性があります。そのため、このファイルは最小権限アクセスを付与することで保護する必要があります。シーリングキーの更新や手動シーリングキー管理などの追加ガイダンスについては、[ドキュメント](https://github.com/bitnami-labs/sealed-secrets#secret-rotation)を参照してください。

シーリングキーを保護する一つの選択肢は、`/tmp/master-sealing-key.yaml`ファイルの内容をAWS Systems Manager Parameter StoreのSecureString パラメータとして保存することです。このパラメータはKMSカスタマーマネージドキー（CMK）を使用して保護し、このキーを使用してパラメータを取得できるIAMプリンシパルのセットを制限するためにキーポリシーを使用できます。さらに、KMSでこのCMKの自動ローテーションを有効にすることもできます。標準層パラメータは最大4096文字のパラメータ値をサポートすることに注意してください。そのため、master.yamlファイルのサイズを考慮すると、上級層のパラメータとして保存する必要があります。
