---
title: "デフォルトService Accountへの管理者アクセス"
sidebar_position: 522
tmdTranslationSourceHash: 6fc62e77f108abccfa72bba838ead53d
---

次のラボ演習では、Service Accountにクラスター管理者権限を付与します。これはベストプラクティスではありません。なぜなら、このService Accountを使用するPodが意図せず管理者権限で起動される可能性があり、これらのPodに`exec`アクセスできるユーザーがエスカレーションして、クラスターへの無制限のアクセスを取得できるようになる可能性があるからです。

これをシミュレートするために、`default`名前空間内の`default` Service Accountに`cluster-admin` Cluster Roleをバインドします。

```bash
$ kubectl -n default create rolebinding sa-default-admin --clusterrole cluster-admin --serviceaccount default:default
```

数分以内に[GuardDuty Findingsコンソール](https://console.aws.amazon.com/guardduty/home#/findings)に`Policy:Kubernetes/AdminAccessToDefaultServiceAccount`の検出結果が表示されます。検出結果の詳細、アクション、およびDetective調査を分析するための時間を取りましょう。

![Admin access finding](/docs/security/guardduty/log-monitoring/admin-access-sa.webp)

以下のコマンドを実行して、問題のあるRole Bindingを削除します。

```bash
$ kubectl -n default delete rolebinding sa-default-admin
```
