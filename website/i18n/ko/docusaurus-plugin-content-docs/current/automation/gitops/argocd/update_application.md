---
title: "애플리케이션 업데이트"
sidebar_position: 40
tmdTranslationSourceHash: '0f81209f4be7d294a1527a3ab5b6702d'
---

이제 Argo CD로 애플리케이션을 배포했으므로, GitOps 원칙을 사용하여 구성을 업데이트하는 방법을 살펴보겠습니다. 이 예제에서는 Helm values를 사용하여 `ui` Deployment의 `replicas` 수를 1에서 3으로 증가시킵니다.

먼저, replica 수를 구성하는 `values.yaml` 파일을 생성합니다:

::yaml{file="manifests/modules/automation/gitops/argocd/update-application/values.yaml"}

이 구성 파일을 Git 저장소 디렉터리에 복사하겠습니다:

```bash
$ cp ~/environment/eks-workshop/modules/automation/gitops/argocd/update-application/values.yaml \
  ~/environment/argocd/ui
```

이 파일을 추가한 후, Git 디렉터리 구조는 다음과 같이 보여야 합니다:

```bash
$ tree ~/environment/argocd
`-- ui
    |-- Chart.yaml
    `-- values.yaml
```

이제 변경 사항을 커밋하고 Git 저장소에 푸시합니다:

```bash
$ git -C ~/environment/argocd add .
$ git -C ~/environment/argocd commit -am "Update UI service replicas"
$ git -C ~/environment/argocd push
```

이 시점에서 Argo CD는 저장소의 애플리케이션 상태가 변경되었음을 감지합니다. Argo CD UI에서 `Refresh`를 클릭한 다음 `Sync`를 클릭하거나, `argocd` CLI를 사용하여 애플리케이션을 동기화할 수 있습니다:

```bash
$ argocd app sync ui
$ argocd app wait ui --timeout 120
```

동기화가 완료되면, UI Deployment에 이제 3개의 Pod가 실행되고 있어야 합니다:

![argocd-update-application](/docs/automation/gitops/argocd/argocd-update-application.webp)

업데이트가 성공적으로 완료되었는지 확인하기 위해 Deployment와 Pod 상태를 확인해보겠습니다:

```bash hook=update
$ kubectl get deployment -n ui ui
NAME   READY   UP-TO-DATE   AVAILABLE   AGE
ui     3/3     3            3           3m33s
$ kubectl get pod -n ui
NAME                 READY   STATUS    RESTARTS   AGE
ui-6d5bb7b95-hzmgp   1/1     Running   0          61s
ui-6d5bb7b95-j28ww   1/1     Running   0          61s
ui-6d5bb7b95-rjfxd   1/1     Running   0          3m34s
```

이것은 GitOps가 버전 관리를 통해 구성 변경을 수행할 수 있도록 하는 방법을 보여줍니다. 저장소를 업데이트하고 Argo CD와 동기화함으로써, Kubernetes API와 직접 상호 작용하지 않고도 UI Deployment를 성공적으로 확장했습니다.

