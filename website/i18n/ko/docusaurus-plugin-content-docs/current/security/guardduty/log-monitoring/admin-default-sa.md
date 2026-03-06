---
title: "기본 Service Account에 대한 관리자 액세스"
sidebar_position: 522
tmdTranslationSourceHash: '6fc62e77f108abccfa72bba838ead53d'
---

이번 실습에서는 Service Account에 클러스터 관리자 권한을 부여합니다. 이는 이 Service Account를 사용하는 Pod가 의도치 않게 관리자 권한으로 실행될 수 있어 모범 사례가 아닙니다. 이러한 Pod에 대한 `exec` 액세스 권한이 있는 사용자가 권한을 상승시켜 클러스터에 대한 무제한 액세스를 얻을 수 있습니다.

이를 시뮬레이션하기 위해 `default` 네임스페이스의 `default` Service Account에 `cluster-admin` Cluster Role을 바인딩해야 합니다.

```bash
$ kubectl -n default create rolebinding sa-default-admin --clusterrole cluster-admin --serviceaccount default:default
```

몇 분 안에 [GuardDuty Findings 콘솔](https://console.aws.amazon.com/guardduty/home#/findings)에서 `Policy:Kubernetes/AdminAccessToDefaultServiceAccount` 탐지 결과를 볼 수 있습니다. 시간을 내어 Finding 세부 정보, Action 및 Detective Investigation을 분석해 보세요.

![Admin access finding](/docs/security/guardduty/log-monitoring/admin-access-sa.webp)

다음 명령을 실행하여 문제가 있는 Role Binding을 삭제합니다.

```bash
$ kubectl -n default delete rolebinding sa-default-admin
```

