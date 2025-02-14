---
title: "애플리케이션 배포하기"
sidebar_position: 15
---

클러스터에 Flux를 성공적으로 부트스트랩했으므로 이제 애플리케이션을 배포할 수 있습니다. GitOps 기반 애플리케이션 배포와 다른 방식의 차이점을 보여주기 위해, 현재 `kubectl apply -k` 접근 방식을 사용하는 샘플 애플리케이션의 UI 컴포넌트를 새로운 Flux 배포 방식으로 마이그레이션하겠습니다.

먼저 기존 UI 컴포넌트를 제거하여 교체할 수 있도록 합니다:

```bash
$ kubectl delete -k ~/environment/eks-workshop/base-application/ui
```

다음으로, 이전 섹션에서 Flux를 부트스트랩하는 데 사용했던 리포지토리를 클론합니다:

```bash
$ git clone ssh://${GITOPS_IAM_SSH_KEY_ID}@git-codecommit.${AWS_REGION}.amazonaws.com/v1/repos/${EKS_CLUSTER_NAME}-gitops ~/environment/flux
```

이제 클론된 리포지토리로 이동하여 GitOps 구성을 만들어보겠습니다. UI 서비스에 대한 기존 kustomize 구성을 복사합니다:

```bash
$ mkdir ~/environment/flux/apps
$ cp -R ~/environment/eks-workshop/base-application/ui ~/environment/flux/apps
```

그런 다음 `apps` 디렉토리에 kustomization을 생성해야 합니다:

```file
manifests/modules/automation/gitops/flux/apps-kustomization.yaml
```

이 파일을 Git 리포지토리 디렉토리에 복사합니다:

```bash
$ cp ~/environment/eks-workshop/modules/automation/gitops/flux/apps-kustomization.yaml \
  ~/environment/flux/apps/kustomization.yaml
```

변경 사항을 푸시하기 전 마지막 단계는 Flux가 우리의 `apps` 디렉토리를 인식하도록 하는 것입니다. 이를 위해 `flux` 디렉토리에 추가 파일을 생성합니다:

```file
manifests/modules/automation/gitops/flux/flux-kustomization.yaml
```

이 파일을 Git 리포지토리 디렉토리에 복사합니다:

```bash
$ cp ~/environment/eks-workshop/modules/automation/gitops/flux/flux-kustomization.yaml \
  ~/environment/flux/apps.yaml
```

이제 Git 디렉토리는 다음과 같이 보일 것이며, `tree ~/environment/flux` 명령을 실행하여 확인할 수 있습니다:

```text
.
├── apps
│   ├── kustomization.yaml
│   └── ui
│       ├── configMap.yaml
│       ├── deployment.yaml
│       ├── kustomization.yaml
│       ├── namespace.yaml
│       ├── serviceAccount.yaml
│       └── service.yaml
├── apps.yaml
└── flux-system
    ├── gotk-components.yaml
    ├── gotk-sync.yaml
    └── kustomization.yaml


3 directories, 11 files
```

마지막으로 구성을 CodeCommit에 푸시할 수 있습니다:

```bash
$ git -C ~/environment/flux add .
$ git -C ~/environment/flux commit -am "Adding the UI service"
$ git -C ~/environment/flux push origin main
```

Flux가 CodeCommit의 변경 사항을 감지하고 조정하는 데 시간이 걸릴 것입니다. Flux CLI를 사용하여 새로운 `apps` kustomization이 나타나는 것을 확인할 수 있습니다:

```bash test=false
$ flux get kustomization --watch
NAMESPACE     NAME          AGE   READY   STATUS
flux-system   flux-system   14h   True    Applied revision: main/f39f67e6fb870eed5997c65a58c35f8a58515969
flux-system   apps          34s   True    Applied revision: main/f39f67e6fb870eed5997c65a58c35f8a58515969
```

다음과 같이 Flux를 수동으로 조정하도록 트리거할 수도 있습니다:

```bash wait=30 hook=flux-deployment
$ flux reconcile source git flux-system -n flux-system
```

위에 표시된 대로 `apps`가 나타나면 `Ctrl+C`를 사용하여 명령을 종료하세요. 이제 UI 서비스와 관련된 모든 리소스가 다시 배포되어 있어야 합니다. 확인하려면 다음 명령을 실행하세요:

```bash
$ kubectl get deployment -n ui ui
NAME   READY   UP-TO-DATE   AVAILABLE   AGE
ui     1/1     1            1           5m
$ kubectl get pod -n ui
NAME                  READY   STATUS    RESTARTS   AGE
ui-54ff78779b-qnrrc   1/1     Running   0          5m
```

이제 UI 컴포넌트를 Flux를 사용하여 배포하도록 성공적으로 마이그레이션했으며, Git 리포지토리에 푸시된 추가 변경 사항은 자동으로 EKS 클러스터에 조정될 것입니다.