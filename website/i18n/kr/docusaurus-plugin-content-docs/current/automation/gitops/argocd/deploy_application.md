---
title: "애플리케이션 배포하기"
sidebar_position: 30
---

우리는 클러스터에 Argo CD를 성공적으로 구성했으므로 이제 애플리케이션을 배포할 수 있습니다. GitOps 기반 애플리케이션 배포와 다른 방식의 차이점을 보여주기 위해, 현재 `kubectl apply -k` 접근 방식을 사용하는 샘플 애플리케이션의 UI 컴포넌트를 새로운 Argo CD 배포 방식으로 마이그레이션하겠습니다.

먼저 기존 UI 컴포넌트를 제거하여 교체할 수 있도록 합니다:

```bash
$ kubectl delete -k ~/environment/eks-workshop/base-application/ui --ignore-not-found=true
namespace "ui" deleted
serviceaccount "ui" deleted
configmap "ui" deleted
service "ui" deleted
deployment.apps "ui" deleted
```

이제 클론된 Git 저장소로 이동하여 GitOps 구성을 생성하기 시작하겠습니다. UI 서비스에 대한 기존 kustomize 구성을 복사합니다:

```bash
$ cp -R ~/environment/eks-workshop/base-application/ui/* ~/environment/argocd/apps
```

이제 Git 디렉토리가 다음과 같이 보일 것입니다. `tree ~/environment/argocd` 명령을 실행하여 확인할 수 있습니다:

```text
.
└── apps
    ├── configMap.yaml
    ├── deployment.yaml
    ├── kustomization.yaml
    ├── namespace.yaml
    ├── serviceAccount.yaml
    └── service.yaml

1 directory, 6 files
```

Argo CD UI를 열고 `apps` 애플리케이션으로 이동합니다.

![Application in the ArgoCD UI](assets/argocd-ui-insync-apps.webp)

마지막으로 구성을 Git 저장소에 푸시할 수 있습니다:

```bash
$ git -C ~/environment/argocd add .
$ git -C ~/environment/argocd commit -am "Adding the UI service"
$ git -C ~/environment/argocd push
```

ArgoCD UI에서 `Refresh`와 `Sync`를 클릭하거나 `argocd` CLI를 사용하여 애플리케이션을 `Sync`합니다:

```bash
$ argocd app sync apps
```

잠시 후 애플리케이션이 `Synced` 상태가 되고 리소스가 배포되어야 하며, UI는 다음과 같이 보일 것입니다:

![argocd-deploy-application](assets/argocd-deploy-application.webp)

이는 Argo CD가 기본 kustomization을 생성했으며, 클러스터와 동기화되어 있음을 보여줍니다.

이제 UI 컴포넌트를 Argo CD를 사용하여 배포하도록 성공적으로 마이그레이션했으며, Git 저장소에 푸시된 추가 변경사항은 자동으로 EKS 클러스터에 조정될 것입니다.

이제 UI 서비스와 관련된 모든 리소스가 배포되어 있어야 합니다. 확인하려면 다음 명령을 실행하세요:

```bash hook=deploy
$ kubectl get deployment -n ui ui
NAME   READY   UP-TO-DATE   AVAILABLE   AGE
ui     1/1     1            1           61s
$ kubectl get pod -n ui
NAME                 READY   STATUS   RESTARTS   AGE
ui-6d5bb7b95-rjfxd   1/1     Running  0          62s
```