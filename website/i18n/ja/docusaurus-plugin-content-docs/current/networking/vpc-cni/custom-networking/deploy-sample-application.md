---
title: "ワークロードの再デプロイ"
sidebar_position: 25
tmdTranslationSourceHash: 29da9c8a35ecfcb980663189e5f273c0
---

これまでに行ったカスタムネットワーキングの更新をテストするために、前のステップでプロビジョニングした新しいノードで `checkout` デプロイメントのポッドを実行するように更新しましょう。

変更を行うために、以下のコマンドを実行してクラスター内の `checkout` デプロイメントを変更します：

```bash timeout=240
$ kubectl apply -k ~/environment/eks-workshop/modules/networking/custom-networking/sampleapp
$ kubectl rollout status deployment/checkout -n checkout --timeout 180s
```

このコマンドは `checkout` デプロイメントに `nodeSelector` を追加します。

```kustomization
modules/networking/custom-networking/sampleapp/checkout.yaml
Deployment/checkout
```

「checkout」名前空間にデプロイされたマイクロサービスを確認しましょう。

```bash
$ kubectl get pods -n checkout -o wide
NAME                              READY   STATUS    RESTARTS   AGE   IP             NODE                                         NOMINATED NODE   READINESS GATES
checkout-5fbbc99bb7-brn2m         1/1     Running   0          98s   100.64.10.16   ip-10-42-10-14.us-west-2.compute.internal    <none>           <none>
checkout-redis-6cfd7d8787-8n99n   1/1     Running   0          49m   10.42.12.33    ip-10-42-12-155.us-west-2.compute.internal   <none>           <none>
```

`checkout` ポッドがVPCに追加された `100.64.0.0` CIDRブロックからIPアドレスを割り当てられていることがわかります。まだ再デプロイされていないポッドは、元々VPCに関連付けられていた唯一のCIDRブロックであった `10.42.0.0` CIDRブロックからアドレスを割り当てられたままです。この例では、`checkout-redis` ポッドはまだこの範囲からのアドレスを持っています。
