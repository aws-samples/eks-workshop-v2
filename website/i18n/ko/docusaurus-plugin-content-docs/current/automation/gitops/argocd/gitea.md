---
title: "Gitea 설정"
sidebar_position: 5
tmdTranslationSourceHash: 65f16f55be12d2b448d3eac30d9a4841
---

GitHub나 GitLab의 빠르고 쉬운 대안으로 [Gitea](https://gitea.com)를 사용하겠습니다. Gitea는 사용자 친화적인 웹 인터페이스를 제공하는 경량 자체 호스팅 Git 서비스로, 자체 Git 리포지토리를 빠르게 설정하고 관리할 수 있게 해줍니다. 이는 Kubernetes 매니페스트를 저장하고 버전 관리하는 신뢰할 수 있는 소스로 사용되며, Argo CD로 탐색할 GitOps 워크플로에 필수적입니다.

Helm을 사용하여 EKS 클러스터에 Gitea를 설치해 보겠습니다:

```bash
$ helm upgrade --install gitea oci://docker.gitea.com/charts/gitea \
  --version "$GITEA_CHART_VERSION" \
  --namespace gitea --create-namespace \
  --values ~/environment/eks-workshop/modules/automation/gitops/argocd/gitea/values.yaml \
  --set "gitea.admin.password=${GITEA_PASSWORD}" \
  --wait
```

계속하기 전에 Gitea가 실행 중인지 확인하세요:

```bash timeout=300
$ export GITEA_HOSTNAME=$(kubectl get svc -n gitea gitea-http -o jsonpath="{.status.loadBalancer.ingress[*].hostname}")
$ curl --head -X GET --retry 30 --retry-all-errors --retry-delay 15 \
  --connect-timeout 10 --max-time 60 \
  http://${GITEA_HOSTNAME}:3000
```

Git과 상호작용하려면 SSH 키가 필요합니다. 이 실습을 위한 환경 준비 과정에서 SSH 키가 생성되었으며, Gitea에 등록하기만 하면 됩니다:

```bash
$ curl -X 'POST' \
  "http://workshop-user:$GITEA_PASSWORD@${GITEA_HOSTNAME}:3000/api/v1/user/keys" \
  -H 'accept: application/json' \
  -H 'Content-Type: application/json' \
  -d "{\"key\": \"$SSH_PUBLIC_KEY\",\"read_only\": true,\"title\": \"gitops\"}"
```

또한 Argo CD가 사용할 Gitea 리포지토리를 생성해야 합니다:

```bash
$ curl -X 'POST' \
  "http://workshop-user:$GITEA_PASSWORD@${GITEA_HOSTNAME}:3000/api/v1/user/repos" \
  -H 'accept: application/json' \
  -H 'Content-Type: application/json' \
  -d "{\"name\": \"argocd\"}"
```

이제 Git이 커밋에 사용할 ID를 설정할 수 있습니다:

```bash
$ git config --global user.email "you@eksworkshop.com"
$ git config --global user.name "Your Name"
$ git config --global init.defaultBranch main
$ git config --global core.sshCommand 'ssh -i ~/.ssh/gitops_ssh.pem'
```

마지막으로 리포지토리를 복제하고 초기 구조를 설정하겠습니다:

```bash hook=clone
$ export GITEA_SSH_HOSTNAME=$(kubectl get svc -n gitea gitea-ssh -o jsonpath="{.status.loadBalancer.ingress[*].hostname}")
$ git clone ssh://git@${GITEA_SSH_HOSTNAME}:2222/workshop-user/argocd.git ~/environment/argocd
$ git -C ~/environment/argocd checkout -b main
Switched to a new branch 'main'
$ touch ~/environment/argocd/.gitkeep
$ git -C ~/environment/argocd add .
$ git -C ~/environment/argocd commit -am "Initial commit"
$ git -C ~/environment/argocd push --set-upstream origin main
```

