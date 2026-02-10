---
title: "制限的な PSS プロファイル"
sidebar_position: 63
tmdTranslationSourceHash: b318b5d3cd34989c6d33d2a6558d0c68
---

最後に、最も厳しく制限された現在のポッドのセキュリティベストプラクティスに従ったポリシーである制限的なプロファイルを見てみましょう。`pss` 名前空間に制限的な PSS プロファイルのすべての PSA モードを有効にするラベルを追加します：

```kustomization
modules/security/pss-psa/restricted-namespace/namespace.yaml
Namespace/pss
```

Kustomize を実行してこの変更を適用し、`pss` 名前空間にラベルを追加します：

```bash
$ kubectl apply -k ~/environment/eks-workshop/modules/security/pss-psa/restricted-namespace
Warning: existing pods in namespace "pss" violate the new PodSecurity enforce level "restricted:latest"
Warning: pss-d59d88b99-flkgp: allowPrivilegeEscalation != false, runAsNonRoot != true, seccompProfile
namespace/pss configured
deployment.apps/pss unchanged
```

ベースラインプロファイルと同様に、pss デプロイメントが制限的なプロファイルに違反しているという警告が表示されます。

```bash
$ kubectl -n pss delete pod --all
pod "pss-d59d88b99-flkgp" deleted
```

ポッドは再作成されません：

```bash hook=no-pods
$ kubectl -n pss get pod
No resources found in pss namespace.
```

上記の出力は、ポッドのセキュリティ設定が制限的な PSS プロファイルに違反しているため、PSA が `pss` 名前空間内のポッドの作成を許可しなかったことを示しています。この動作は、前のセクションで見たものと同じです。

制限的なプロファイルの場合、実際にプロファイルを満たすためにセキュリティ設定を事前にロックダウンする必要があります。`pss` 名前空間に設定された特権的な PSS プロファイルに準拠するようにポッド設定にいくつかのセキュリティコントロールを追加しましょう：

```kustomization
modules/security/pss-psa/restricted-workload/deployment.yaml
Deployment/pss
```

Kustomize を実行してこれらの変更を適用し、デプロイメントを再作成します：

```bash
$ kubectl apply -k ~/environment/eks-workshop/modules/security/pss-psa/restricted-workload
namespace/pss unchanged
deployment.apps/pss configured
$ kubectl rollout status -n pss deployment/pss --timeout=60s
```

次に、以下のコマンドを実行して、PSA が上記の変更を持つ `pss` 名前空間内のデプロイメントとポッドの作成を許可するかどうかを確認します：

```bash
$ kubectl -n pss get pod
NAME                     READY   STATUS    RESTARTS   AGE
pss-8dd6fc8c6-9kptf      1/1     Running   0          3m6s
```

上記の出力は、ポッドのセキュリティ設定が制限的な PSS プロファイルに適合しているため、PSA が許可したことを示しています。

上記のセキュリティ権限は、制限的な PSS プロファイルで許可されているコントロールの包括的なリストではないことに注意してください。各 PSS プロファイルで許可/禁止されている詳細なセキュリティコントロールについては、[ドキュメント](https://kubernetes.io/docs/concepts/security/pod-security-standards/#restricted)を参照してください。
