---
title: "kube-system 네임스페이스에서의 안전하지 않은 실행"
sidebar_position: 521
tmdTranslationSourceHash: 'daf844a34429235a12e224ed5693e81a'
---

이 탐지 결과는 EKS 클러스터의 `kube-system` 네임스페이스에 있는 Pod 내부에서 명령이 실행되었음을 나타냅니다.

먼저 셸 환경에 대한 액세스를 제공하는 Pod를 `kube-system` 네임스페이스에서 실행해 보겠습니다.

```bash
$ kubectl -n kube-system run nginx --image=nginx
$ kubectl wait --for=condition=ready pod nginx -n kube-system
$ kubectl -n kube-system get pod nginx
NAME    READY   STATUS    RESTARTS   AGE
nginx   1/1     Running   0          28s
```

그런 다음 아래 명령을 실행하여 `Execution:Kubernetes/ExecInKubeSystemPod` 탐지 결과를 생성합니다:

```bash
$ kubectl -n kube-system exec nginx -- pwd
/
```

몇 분 후 [GuardDuty Findings 콘솔](https://console.aws.amazon.com/guardduty/home#/findings)에서 `Execution:Kubernetes/ExecInKubeSystemPod` 탐지 결과를 확인할 수 있습니다.

![Exec finding](/docs/security/guardduty/log-monitoring/exec-finding.webp)

탐지 결과를 클릭하면 화면 오른쪽에 탭이 열리며 탐지 결과 세부 정보와 간단한 설명이 표시됩니다.

![Finding details](/docs/security/guardduty/log-monitoring/finding-details.webp)

또한 Amazon Detective를 사용하여 탐지 결과를 조사할 수 있는 옵션도 제공됩니다.

![Investigate finding](/docs/security/guardduty/log-monitoring/investigate.webp)

탐지 결과의 **Action**을 확인하면 `KUBERNETES_API_CALL`과 관련이 있음을 알 수 있습니다.

![Finding action](/docs/security/guardduty/log-monitoring/finding-action.webp)

탐지 결과를 생성하는 데 사용한 문제가 있는 Pod를 정리합니다:

```bash
$ kubectl -n kube-system delete pod nginx
```

