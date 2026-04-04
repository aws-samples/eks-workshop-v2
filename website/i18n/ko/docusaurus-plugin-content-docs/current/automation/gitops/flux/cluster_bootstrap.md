---
title: "클러스터 부트스트랩"
sidebar_position: 15
tmdTranslationSourceHash: '8817bad0efc303d4114e617ba7ee4a6d'
---

부트스트랩 프로세스는 클러스터에 Flux 컴포넌트를 설치하고 Flux를 사용하여 GitOps로 클러스터 객체를 관리하기 위한 관련 파일을 리포지토리 내에 생성합니다.

클러스터를 부트스트랩하기 전에 Flux는 모든 것이 올바르게 설정되었는지 확인하기 위해 사전 부트스트랩 검사를 실행할 수 있습니다. Flux CLI가 검사를 수행하도록 다음 명령을 실행하세요:

```bash
$ flux check --pre
> checking prerequisites
...
> prerequisites checks passed
```

이제 Gitea 리포지토리를 사용하여 EKS 클러스터에 Flux를 부트스트랩할 수 있습니다:

```bash
$ export GITEA_SSH_HOSTNAME=$(kubectl get svc -n gitea gitea-ssh -o jsonpath="{.status.loadBalancer.ingress[*].hostname}")
$ flux bootstrap git \
   --url=ssh://git@${GITEA_SSH_HOSTNAME}:2222/workshop-user/flux.git \
   --branch=main \
   --private-key-file=${HOME}/.ssh/gitops_ssh.pem \
   --network-policy=false --silent
```

위 명령을 분석해 보겠습니다:

- 먼저 Flux에 상태를 저장하는 데 사용할 Git 리포지토리를 지정합니다
- 그 다음, 이 Flux 인스턴스가 사용할 Git `branch`를 전달합니다. 일부 패턴은 동일한 Git 리포지토리에서 여러 브랜치를 사용하기 때문입니다
- 인증 자격 증명을 제공하고 Flux가 SSH 대신 이를 사용하여 Git에 인증하도록 지시합니다
- 마지막으로 이 워크숍을 위해 특별히 설정을 간소화하기 위한 일부 구성을 제공합니다

:::caution

위의 Flux 설치 방법은 프로덕션 환경에는 적합하지 않으며, 프로덕션 환경에서는 [공식 문서](https://fluxcd.io/flux/installation/)를 따라야 합니다.

:::

이제 다음 명령을 실행하여 부트스트랩 프로세스가 성공적으로 완료되었는지 확인해 보겠습니다:

```bash
$ flux get kustomization
NAME           REVISION            SUSPENDED    READY   MESSAGE
flux-system    main@sha1:6e6ae1d   False        True    Applied revision: main@sha1:6e6ae1d
```

이는 Flux가 기본 kustomization을 생성했으며, 클러스터와 동기화되어 있음을 보여줍니다.

