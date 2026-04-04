---
title: "애플리케이션 배포"
sidebar_position: 15
tmdTranslationSourceHash: adf046743d7e3a4089ea63df04395056
---

클러스터에 Flux를 성공적으로 부트스트랩했으므로 이제 애플리케이션을 배포할 수 있습니다. GitOps 기반 애플리케이션 배포와 다른 방법의 차이점을 보여주기 위해, 현재 `kubectl apply -k` 방식을 사용하고 있는 샘플 애플리케이션의 UI 컴포넌트를 새로운 Flux 배포 방식으로 마이그레이션하겠습니다.

먼저 기존 UI 컴포넌트를 제거하여 교체할 수 있도록 합니다:

```bash
$ kubectl delete namespace ui
```

다음으로, 이전 섹션에서 Flux를 부트스트랩하는 데 사용한 리포지토리를 클론합니다:

```bash hook=clone
$ git clone ssh://git@${GITEA_SSH_HOSTNAME}:2222/workshop-user/flux.git
```

이제 "apps"를 위한 디렉토리를 생성하여 Flux 리포지토리를 채우기 시작하겠습니다. 이 디렉토리는 각 애플리케이션 컴포넌트의 하위 디렉토리를 포함하도록 설계되었습니다:

```bash
$ mkdir ~/environment/flux/apps
```

그런 다음 Flux가 해당 디렉토리를 인식할 수 있도록 kustomization을 생성합니다:

::yaml{file="manifests/modules/automation/gitops/flux/basic/apps.yaml" paths="metadata.name,spec.interval,spec.path"}

1. kustomization에 인식 가능한 이름을 지정합니다
2. Flux에게 매 분마다 폴링하도록 지시합니다
3. Git 리포지토리의 `apps` 경로를 사용합니다

이 파일을 Git 리포지토리 디렉토리에 복사합니다:

```bash
$ cp ~/environment/eks-workshop/modules/automation/gitops/flux/basic/apps.yaml \
  ~/environment/flux/apps.yaml
```

[Amazon ECR Public](https://gallery.ecr.aws/)에 게시된 Helm 차트를 사용하여 애플리케이션 컴포넌트를 설치할 것입니다.

Flux에게 차트를 가져올 위치를 알려주는 HelmRepository 리소스를 생성하겠습니다:

::yaml{file="manifests/modules/automation/gitops/flux/basic/apps/repository.yaml" paths="spec.url,spec.type,spec.interval"}

1. Helm 리포지토리의 URL
2. ECR Public은 Helm 차트를 OCI 아티팩트로 호스팅합니다
3. 5분마다 업데이트를 확인합니다

이 파일을 Git 리포지토리 디렉토리에 복사합니다:

```bash
$ cp ~/environment/eks-workshop/modules/automation/gitops/flux/basic/apps/repository.yaml \
  ~/environment/flux/apps/repository.yaml
```

마지막으로 Flux에게 ui 컴포넌트용 Helm 차트를 설치하도록 지시합니다:

::yaml{file="manifests/modules/automation/gitops/flux/basic/apps/ui/helm.yaml" paths="metadata.name,spec.chart,spec.install.createNamespace,spec.values"}

1. HelmRelease 리소스의 이름
2. 위에서 지정한 Helm 리포지토리를 참조하여 설치할 차트의 이름과 버전
3. 네임스페이스가 존재하지 않으면 생성합니다
4. `values`를 사용하여 차트를 구성합니다. 이 경우 ingress를 활성화합니다

적절한 파일을 Git 리포지토리 디렉토리에 복사합니다:

```bash
$ cp -R ~/environment/eks-workshop/modules/automation/gitops/flux/basic/apps/ui \
  ~/environment/flux/apps
```

이제 Git 디렉토리는 다음과 같이 보일 것이며, `tree ~/environment/flux`를 실행하여 확인할 수 있습니다:

```text
.
├── apps
│   ├── repository.yaml
│   └── ui
│       ├── helm.yaml
│       └── kustomization.yaml
├── apps.yaml
└── flux-system
    ├── gotk-components.yaml
    ├── gotk-sync.yaml
    └── kustomization.yaml


3 directories, 7 files
```

마지막으로 구성을 Git에 푸시할 수 있습니다:

```bash
$ git -C ~/environment/flux add .
$ git -C ~/environment/flux commit -am "Adding the UI service"
$ git -C ~/environment/flux push origin main
```

Flux가 Git의 변경 사항을 인지하고 조정하는 데 시간이 걸립니다. Flux CLI를 사용하여 새로운 `apps` kustomization이 나타나는지 확인할 수 있습니다:

```bash test=false
$ flux get kustomization --watch --timeout=10m
NAME           REVISION            SUSPENDED    READY   MESSAGE
flux-system    main@sha1:f39f67e   False        True    Applied revision: main@sha1:f39f67e
apps           main@sha1:f39f67e   False        True    Applied revision: main@sha1:f39f67e
```

다음과 같이 Flux를 수동으로 트리거하여 조정할 수도 있습니다:

```bash wait=30 hook=flux-deployment
$ flux reconcile source git flux-system -n flux-system
```

위와 같이 `apps`가 나타나면 `Ctrl+C`를 사용하여 명령을 닫습니다. 이제 UI 서비스와 관련된 모든 리소스가 다시 배포되어야 합니다. 확인하려면 다음 명령을 실행하세요:

```bash
$ kubectl get deployment -n ui ui
NAME   READY   UP-TO-DATE   AVAILABLE   AGE
ui     1/1     1            1           5m
$ kubectl get pod -n ui
NAME                  READY   STATUS    RESTARTS   AGE
ui-54ff78779b-qnrrc   1/1     Running   0          5m
```

Ingress 리소스에서 URL을 가져옵니다:

```bash
$ ADDRESS=$(kubectl get ingress -n ui ui -o jsonpath="{.status.loadBalancer.ingress[*].hostname}")
$ echo "http://${ADDRESS}"
http://k8s-ui-ui-a9797f0f61.elb.us-west-2.amazonaws.com
```

로드 밸런서 프로비저닝이 완료될 때까지 기다리려면 다음 명령을 실행할 수 있습니다:

```bash timeout=300
$ curl --head -X GET --retry 30 --retry-all-errors --retry-delay 15 \
  --connect-timeout 10 --max-time 60 \
  $(kubectl get ingress -n ui ui -o jsonpath="{.status.loadBalancer.ingress[*].hostname}")
```

웹 브라우저에서 해당 주소에 접속하세요. 웹 스토어의 UI가 표시되고 사용자로서 사이트를 탐색할 수 있습니다.

<Browser url="http://k8s-ui-ui-a9797f0f61.elb.us-west-2.amazonaws.com">
<img src={require('@site/static/img/sample-app-screens/home.webp').default}/>
</Browser>

