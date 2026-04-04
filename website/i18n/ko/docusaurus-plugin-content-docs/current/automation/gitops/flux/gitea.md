---
title: "Gitea 설정"
sidebar_position: 5
tmdTranslationSourceHash: '81a4c85f3ba8bb568bde3044b3cdfecc'
---

GitHub나 GitLab 대신 빠르고 쉬운 대안으로 [Gitea](https://gitea.com)를 사용하겠습니다. Gitea는 사용자 친화적인 웹 인터페이스를 제공하는 경량 자체 호스팅 Git 서비스로, 자체 Git 리포지터리를 빠르게 설정하고 관리할 수 있게 해줍니다. 이는 Kubernetes 매니페스트를 저장하고 버전 관리하기 위한 단일 진실 공급원(source of truth) 역할을 하며, Flux를 사용하여 탐색할 GitOps 워크플로에 필수적입니다.

Helm을 사용하여 EKS 클러스터에 Gitea를 설치해보겠습니다:

```bash
$ helm upgrade --install gitea oci://docker.gitea.com/charts/gitea \
  --version "$GITEA_CHART_VERSION" \
  --namespace gitea --create-namespace \
  --values ~/environment/eks-workshop/modules/automation/gitops/flux/gitea/values.yaml \
  --set "gitea.admin.password=${GITEA_PASSWORD}" \
  --wait
```

진행하기 전에 Gitea가 실행 중인지 확인하세요:

```bash timeout=300 wait=10
$ export GITEA_HOSTNAME=$(kubectl get svc -n gitea gitea-http -o jsonpath="{.status.loadBalancer.ingress[*].hostname}")
$ curl --head -X GET --retry 30 --retry-all-errors --retry-delay 15 \
  --connect-timeout 10 --max-time 60 \
  http://${GITEA_HOSTNAME}:3000
```

Git과 상호작용하려면 SSH 키가 필요합니다. 이 실습을 위한 환경 준비 과정에서 이미 생성되었으므로, Gitea에 등록하기만 하면 됩니다:

```bash
$ curl -X 'POST' --retry 3 --retry-all-errors \
  "http://workshop-user:$GITEA_PASSWORD@${GITEA_HOSTNAME}:3000/api/v1/user/keys" \
  -H 'accept: application/json' \
  -H 'Content-Type: application/json' \
  -d "{\"key\": \"$SSH_PUBLIC_KEY\",\"read_only\": true,\"title\": \"gitops\"}"
```

그리고 Flux가 사용할 Gitea 리포지터리도 생성해야 합니다:

```bash
$ curl -X 'POST' --retry 3 --retry-all-errors \
  "http://workshop-user:$GITEA_PASSWORD@${GITEA_HOSTNAME}:3000/api/v1/user/repos" \
  -H 'accept: application/json' \
  -H 'Content-Type: application/json' \
  -d "{\"name\": \"flux\"}"
```

마지막으로 Git이 커밋에 사용할 신원을 설정할 수 있습니다:

```bash
$ git config --global user.email "you@eksworkshop.com"
$ git config --global user.name "Your Name"
$ git config --global init.defaultBranch main
$ git config --global core.sshCommand 'ssh -i ~/.ssh/gitops_ssh.pem'
```

