---
title: "テストワークロード"
sidebar_position: 10
kiteTranslationSourceHash: 0836ea86d96c1022cfd665158d741f09
---

PSSのさまざまな機能をテストするために、まずEKSクラスターにテストに使用できるワークロードをデプロイしましょう。カタログコンポーネントの別のデプロイメントを独自の名前空間で作成して実験します：

::yaml{file="manifests/modules/security/pss-psa/workload/deployment.yaml"}

これをクラスターに適用します：

```bash
$ kubectl apply -k ~/environment/eks-workshop/modules/security/pss-psa/workload
namespace/pss created
deployment.apps/pss created
$ kubectl rollout status -n pss deployment/pss --timeout=60s
```

