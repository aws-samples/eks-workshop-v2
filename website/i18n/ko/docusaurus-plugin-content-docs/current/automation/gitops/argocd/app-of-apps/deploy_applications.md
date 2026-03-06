---
title: "더 많은 워크로드 추가하기"
sidebar_position: 60
tmdTranslationSourceHash: '47bf999b2ab55006d4340855848db799'
---

이제 App of Apps 패턴의 기초를 설정했으므로, Git 리포지토리에 추가 워크로드 Helm 차트를 추가할 수 있습니다.

애플리케이션 차트를 추가한 후 리포지토리 구조는 다음과 같습니다:

```text
.
|-- app-of-apps
|   |-- ...
|-- carts
|   `-- Chart.yaml
|-- catalog
|   `-- Chart.yaml
|-- checkout
|   `-- Chart.yaml
|-- orders
|   `-- Chart.yaml
`-- ui
    `-- Chart.yaml
```

애플리케이션 차트 파일들을 Git 리포지토리 디렉토리로 복사해 봅시다:

```bash
$ cp -R ~/environment/eks-workshop/modules/automation/gitops/argocd/app-charts/* \
  ~/environment/argocd/
```

다음으로, 이러한 변경 사항을 Git 리포지토리에 커밋하고 푸시합니다:

```bash
$ git -C ~/environment/argocd add .
$ git -C ~/environment/argocd commit -am "Adding apps charts"
$ git -C ~/environment/argocd push
```

apps 애플리케이션을 동기화합니다:

```bash
$ argocd app sync apps
$ argocd app wait -l app.kubernetes.io/created-by=eks-workshop
```

Argo CD가 프로세스를 완료하면, 모든 애플리케이션이 Argo CD UI에 표시된 것처럼 `Synced` 상태가 됩니다:

![argocd-ui-apps.png](/docs/automation/gitops/argocd/app-of-apps/argocd-ui-apps-synced.webp)

이제 각 애플리케이션 컴포넌트가 배포된 새로운 네임스페이스 세트가 표시되어야 합니다:

```bash hook=deploy
$ kubectl get namespaces
NAME              STATUS   AGE
argocd            Active   18m
carts             Active   28s
catalog           Active   28s
checkout          Active   28s
default           Active   8h
gitea             Active   19m
kube-node-lease   Active   8h
kube-public       Active   8h
kube-system       Active   8h
orders            Active   28s
ui                Active   11m
```

배포된 워크로드 중 하나를 자세히 살펴보겠습니다. 예를 들어, carts 컴포넌트를 확인할 수 있습니다:

```bash
$ kubectl get deployment -n carts
NAME    READY   UP-TO-DATE   AVAILABLE   AGE
carts   1/1     1            1           46s
```

이를 통해 App of Apps 패턴을 사용한 GitOps 기반 배포가 모든 마이크로서비스를 클러스터에 성공적으로 배포했음을 확인할 수 있습니다.

