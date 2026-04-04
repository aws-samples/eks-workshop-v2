---
title: "설정"
sidebar_position: 50
tmdTranslationSourceHash: eb35c190aa687bbad32f257a72d48394
---

Helm 차트와 함께 DRY(Don't Repeat Yourself) 접근 방식을 사용하여 Argo CD 애플리케이션 세트에 대한 템플릿을 생성하겠습니다:

```text
.
|-- app-of-apps
|   |-- Chart.yaml
|   |-- templates
|   |   |-- _application.yaml
|   |   `-- application.yaml
|   `-- values.yaml
|-- ui
`-- catalog
    ...
```

`_application.yaml`은 컴포넌트 이름 목록을 기반으로 애플리케이션을 동적으로 생성하는 데 사용되는 템플릿 파일입니다:

<!-- prettier-ignore-start -->
::yaml{file="manifests/modules/automation/gitops/argocd/app-of-apps/templates/_application.yaml"}
<!-- prettier-ignore-end -->

`values.yaml` 파일은 Argo CD 애플리케이션이 생성될 컴포넌트 목록과 모든 애플리케이션에 공통으로 적용될 Git 리포지토리 관련 설정을 지정합니다:

::yaml{file="manifests/modules/automation/gitops/argocd/app-of-apps/values.yaml" paths="spec.destination.server,spec.source,applications"}

1. 애플리케이션이 배포될 Kubernetes API 서버 엔드포인트를 지정합니다 (로컬 클러스터)
2. `${GITOPS_REPO_URL_ARGOCD}` 환경 변수를 사용하여 애플리케이션 매니페스트가 포함된 Git 리포지토리와 추적할 Git 브랜치(`main`)를 지정합니다
3. `applications` 목록은 배포할 애플리케이션의 이름을 지정합니다

먼저, 이 기본 App of Apps 설정을 Git 디렉토리에 복사하겠습니다:

```bash
$ export GITOPS_REPO_URL_ARGOCD="ssh://git@${GITEA_SSH_HOSTNAME}:2222/workshop-user/argocd.git"
$ cp -R ~/environment/eks-workshop/modules/automation/gitops/argocd/app-of-apps ~/environment/argocd/
$ yq -i ".spec.source.repoURL = env(GITOPS_REPO_URL_ARGOCD)" ~/environment/argocd/app-of-apps/values.yaml
```

이제 이러한 변경 사항을 Git 리포지토리에 커밋하고 푸시하겠습니다:

```bash wait=10
$ git -C ~/environment/argocd add .
$ git -C ~/environment/argocd commit -am "Adding App of Apps"
$ git -C ~/environment/argocd push
```

다음으로, App of Apps 패턴을 구현하기 위해 새로운 Argo CD Application을 생성해야 합니다. 이 과정에서 `--sync-policy automated` 플래그를 사용하여 Git 리포지토리의 설정과 클러스터의 상태를 자동으로 [동기화](https://argo-cd.readthedocs.io/en/stable/user-guide/auto_sync/)하도록 Argo CD를 활성화하겠습니다:

```bash
$ argocd app create apps --repo ssh://git@${GITEA_SSH_HOSTNAME}:2222/workshop-user/argocd.git \
  --dest-server https://kubernetes.default.svc \
  --sync-policy automated --self-heal --auto-prune \
  --set-finalizer \
  --upsert \
  --path app-of-apps
 application 'apps' created
$ argocd app wait apps --timeout 120
```

Argo CD UI를 열고 메인 "Applications" 페이지로 이동합니다. App of Apps 설정이 배포되고 동기화되었지만, UI 컴포넌트를 제외한 모든 워크로드 앱이 "Unknown"으로 표시됩니다.

![argocd-ui-apps.png](/docs/automation/gitops/argocd/app-of-apps/argocd-ui-apps-unknown.webp)

다음 단계에서 워크로드에 대한 설정을 배포하겠습니다.

