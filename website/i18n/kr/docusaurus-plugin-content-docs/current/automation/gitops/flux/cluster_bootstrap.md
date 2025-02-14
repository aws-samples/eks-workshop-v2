---
title: "클러스터 부트스트랩"
sidebar_position: 15
---

부트스트랩 프로세스는 클러스터에 Flux 컴포넌트를 설치하고 Flux를 사용한 GitOps로 클러스터 객체를 관리하기 위한 저장소 내의 관련 파일들을 생성합니다.

클러스터를 부트스트랩하기 전에, Flux는 모든 것이 올바르게 설정되었는지 확인하기 위해 사전 부트스트랩 검사를 실행할 수 있게 합니다. Flux CLI가 검사를 수행하도록 다음 명령을 실행하세요:

```bash
$ flux check --pre
> checking prerequisites
...
> prerequisites checks passed
```

이제 CodeCommit 저장소를 사용하여 EKS 클러스터에 Flux를 부트스트랩해 보겠습니다:

```bash
$ flux bootstrap git \
  --url=ssh://${GITOPS_IAM_SSH_KEY_ID}@git-codecommit.${AWS_REGION}.amazonaws.com/v1/repos/${EKS_CLUSTER_NAME}-gitops \
  --branch=main \
  --private-key-file=${HOME}/.ssh/gitops_ssh.pem \
  --components-extra=image-reflector-controller,image-automation-controller \
  --network-policy=false \
  --silent
```

위 명령을 분석해 보겠습니다:

- 먼저 Flux에게 상태를 저장할 Git 저장소를 알려줍니다
- 그 다음, 일부 패턴에서는 동일한 Git 저장소에서 여러 브랜치를 사용하므로, 이 Flux 인스턴스가 사용할 Git `branch`를 전달합니다
- `--components-extra` 매개변수를 사용하여 지속적 통합 섹션에서 사용할 [추가 툴킷 컴포넌트](https://fluxcd.io/flux/components/image/)를 설치합니다
- 마지막으로 Flux가 `/home/ec2-user/gitops_ssh.pem`에 있는 SSH 키를 사용하여 연결하고 인증하기 위해 SSH를 사용할 것입니다

이제 다음 명령을 실행하여 부트스트랩 프로세스가 성공적으로 완료되었는지 확인해 보겠습니다:

```bash
$ flux get kustomization
NAME            REVISION        SUSPENDED       READY   MESSAGE
flux-system     main/6e6ae1d    False           True    Applied revision: main/6e6ae1d
```

이는 Flux가 기본 kustomization을 생성했고, 클러스터와 동기화되어 있음을 보여줍니다.