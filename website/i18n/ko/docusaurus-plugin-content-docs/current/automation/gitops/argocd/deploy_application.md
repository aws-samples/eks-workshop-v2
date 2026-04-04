---
title: "애플리케이션 배포"
sidebar_position: 30
tmdTranslationSourceHash: 'f2ab388708b4751ac24fbc2d1dddc667'
---

클러스터에 Argo CD를 성공적으로 구성했으니, 이제 애플리케이션을 배포해 보겠습니다. GitOps 기반 배포 방식과 기존 배포 방법의 차이를 보여드리기 위해, 샘플 애플리케이션의 UI 컴포넌트를 `kubectl apply -k` 방식에서 Argo CD 관리 배포로 마이그레이션하겠습니다.

Argo CD 애플리케이션은 환경에 배포된 애플리케이션 인스턴스를 나타내는 Custom Resource Definition (CRD)입니다. 애플리케이션 이름, Git 리포지토리 위치, Kubernetes 매니페스트 경로와 같은 주요 정보를 정의합니다. 애플리케이션 리소스는 또한 원하는 상태, 대상 리비전, 동기화 정책, 상태 확인 정책을 지정합니다.

먼저, 클러스터에서 기존 샘플 애플리케이션을 제거하겠습니다:

```bash
$ kubectl delete namespace -l app.kubernetes.io/created-by=eks-workshop
namespace "carts" deleted
namespace "catalog" deleted
namespace "checkout" deleted
namespace "orders" deleted
namespace "other" deleted
namespace "ui" deleted
```

이제 Git 리포지토리를 간단한 Helm 차트로 채우겠습니다. 이 차트는 UI 컴포넌트의 공개 차트를 Helm 종속성으로 사용하여 래핑합니다:

::yaml{file="manifests/modules/automation/gitops/argocd/Chart.yaml" paths="name,type,version,dependencies.0"}

1. 래퍼 Helm 차트의 이름
2. 이 차트가 애플리케이션을 배포함을 나타냅니다
3. 차트의 버전을 지정합니다
4. AWS의 공개 OCI 레지스트리에서 retail store UI 컴포넌트의 이름, 별칭 및 버전을 래퍼 Helm 차트의 종속성으로 지정합니다

이 파일을 Git 디렉토리에 복사하겠습니다:

```bash
$ mkdir -p ~/environment/argocd/ui
$ cp ~/environment/eks-workshop/modules/automation/gitops/argocd/Chart.yaml \
  ~/environment/argocd/ui
```

Git 디렉토리는 이제 다음과 같은 구조를 가져야 합니다:

```bash
$ tree ~/environment/argocd
`-- ui
    `-- Chart.yaml
```

이제 구성을 Git 리포지토리에 푸시하겠습니다:

```bash
$ git -C ~/environment/argocd add .
$ git -C ~/environment/argocd commit -am "Adding the UI service"
$ git -C ~/environment/argocd push
```

다음으로, Git 리포지토리를 사용하도록 구성된 Argo CD Application을 생성하겠습니다:

```bash
$ argocd app create ui --repo ssh://git@${GITEA_SSH_HOSTNAME}:2222/workshop-user/argocd.git \
  --path ui --dest-server https://kubernetes.default.svc \
  --dest-namespace ui --sync-option CreateNamespace=true
application 'ui' created
```

애플리케이션이 생성되었는지 확인할 수 있습니다:

```bash
$ argocd app list
NAME         CLUSTER                         NAMESPACE  PROJECT  STATUS     HEALTH   SYNCPOLICY  CONDITIONS
argocd/ui    https://kubernetes.default.svc  ui         default  OutOfSync  Missing  Manual      <none>
```

이 애플리케이션은 이제 Argo CD UI에서 볼 수 있습니다:

![Application in the Argo CD UI](/docs/automation/gitops/argocd/argocd-ui-outofsync.webp)

또는 `kubectl` 명령을 사용하여 Argo CD 객체와 직접 상호작용할 수도 있습니다:

```bash
$ kubectl get applications.argoproj.io -n argocd
NAME   SYNC STATUS   HEALTH STATUS
apps   OutOfSync     Missing
```

Argo CD UI를 열고 `apps` 애플리케이션으로 이동하면 다음을 볼 수 있습니다:

![Application in the Argo CD UI](/docs/automation/gitops/argocd/argocd-ui-outofsync-apps.webp)

Argo CD에서 "out of sync"는 Git 리포지토리에 정의된 원하는 상태가 Kubernetes 클러스터의 실제 상태와 일치하지 않음을 나타냅니다. Argo CD는 자동 동기화가 가능하지만, 지금은 이 프로세스를 수동으로 트리거하겠습니다:

```bash
$ argocd app sync ui
$ argocd app wait ui --timeout 120
```

짧은 시간 후에 애플리케이션은 `Synced` 상태에 도달해야 하며, 모든 리소스가 배포됩니다. UI는 다음과 같이 보여야 합니다:

![argocd-deploy-application](/docs/automation/gitops/argocd/argocd-deploy-application.webp)

이것은 Argo CD가 Helm 차트를 성공적으로 설치했으며 이제 클러스터와 동기화되었음을 확인합니다.

이제 UI 컴포넌트를 Argo CD를 사용하여 배포하도록 성공적으로 마이그레이션했습니다. Git 리포지토리에 푸시되는 향후 변경 사항은 자동으로 EKS 클러스터에 조정됩니다.

UI 서비스와 관련된 모든 리소스가 배포되었는지 확인하려면 다음 명령을 실행하세요:

```bash hook=deploy
$ kubectl get deployment -n ui ui
NAME   READY   UP-TO-DATE   AVAILABLE   AGE
ui     1/1     1            1           61s
$ kubectl get pod -n ui
NAME                 READY   STATUS   RESTARTS   AGE
ui-6d5bb7b95-rjfxd   1/1     Running  0          62s
```

