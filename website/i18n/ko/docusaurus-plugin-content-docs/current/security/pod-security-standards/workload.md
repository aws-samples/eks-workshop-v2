---
title: "테스트 워크로드"
sidebar_position: 10
tmdTranslationSourceHash: '0836ea86d96c1022cfd665158d741f09'
---

PSS의 다양한 기능을 테스트하기 위해 먼저 EKS 클러스터에 워크로드를 배포하여 실험에 사용하겠습니다. catalog 컴포넌트의 별도 배포를 자체 네임스페이스에 생성하겠습니다:

::yaml{file="manifests/modules/security/pss-psa/workload/deployment.yaml"}

이를 클러스터에 적용합니다:

```bash
$ kubectl apply -k ~/environment/eks-workshop/modules/security/pss-psa/workload
namespace/pss created
deployment.apps/pss created
$ kubectl rollout status -n pss deployment/pss --timeout=60s
```

