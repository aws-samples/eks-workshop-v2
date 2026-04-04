---
title: "Argo CD 설치"
sidebar_position: 10
weight: 10
tmdTranslationSourceHash: 'd56c4f4c50af1ff2a7b63644e2d44aeb'
---

먼저 클러스터에 Argo CD를 설치해 보겠습니다:

```bash
$ helm repo add argo-cd https://argoproj.github.io/argo-helm
$ helm upgrade --install argocd argo-cd/argo-cd --version "${ARGOCD_CHART_VERSION}" \
  --namespace "argocd" --create-namespace \
  --values ~/environment/eks-workshop/modules/automation/gitops/argocd/values.yaml \
  --wait
NAME: argocd
LAST DEPLOYED: [...]
NAMESPACE: argocd
STATUS: deployed
REVISION: 2
TEST SUITE: None
NOTES:
[...]
```

이 실습에서는 Argo CD 서버 UI가 로드 밸런서가 있는 Kubernetes 서비스를 사용하여 클러스터 외부에서 액세스할 수 있도록 구성되었습니다. URL을 얻으려면 다음 명령을 실행하세요:

```bash
$ export ARGOCD_SERVER=$(kubectl get svc argocd-server -n argocd -o json | jq --raw-output '.status.loadBalancer.ingress[0].hostname')
$ echo "Argo CD URL: https://$ARGOCD_SERVER"
Argo CD URL: https://acfac042a61e5467aace45fc66aee1bf-818695545.us-west-2.elb.amazonaws.com
```

로드 밸런서가 프로비저닝되는 데 시간이 걸립니다. Argo CD가 응답할 때까지 기다리려면 다음 명령을 사용하세요:

```bash timeout=600 wait=60
$ curl --head -X GET --retry 20 --retry-all-errors --retry-delay 15 \
  --connect-timeout 5 --max-time 10 -k \
  https://$ARGOCD_SERVER
curl: (6) Could not resolve host: acfac042a61e5467aace45fc66aee1bf-818695545.us-west-2.elb.amazonaws.com
Warning: Problem : timeout. Will retry in 15 seconds. 20 retries left.
[...]
HTTP/1.1 200 OK
Accept-Ranges: bytes
Content-Length: 788
Content-Security-Policy: frame-ancestors 'self';
Content-Type: text/html; charset=utf-8
X-Frame-Options: sameorigin
X-Xss-Protection: 1
```

인증을 위해 기본 사용자 이름은 `admin`이며 비밀번호는 자동으로 생성됩니다. 다음 명령으로 비밀번호를 가져오세요:

```bash
$ export ARGOCD_PWD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
$ echo "Argo CD admin password: $ARGOCD_PWD"
```

방금 얻은 URL과 자격 증명을 사용하여 Argo CD UI에 로그인하세요. 다음과 같은 인터페이스가 표시됩니다:

![argocd-ui](/docs/automation/gitops/argocd/argocd-ui.webp)

UI 외에도 Argo CD는 애플리케이션을 관리하기 위한 강력한 CLI 도구인 `argocd`를 제공합니다.

:::info
이 실습에서는 `argocd` CLI가 이미 설치되어 있습니다. CLI 도구 설치에 대한 자세한 내용은 [지침](https://argo-cd.readthedocs.io/en/stable/cli_installation/)을 참조하세요.
:::

CLI를 사용하여 Argo CD와 상호 작용하려면 Argo CD 서버로 인증해야 합니다:

```bash
$ argocd login $ARGOCD_SERVER --username admin --password $ARGOCD_PWD --insecure
'admin:login' logged in successfully
Context 'acfac042a61e5467aace45fc66aee1bf-818695545.us-west-2.elb.amazonaws.com' updated
```

마지막으로 Git 리포지토리를 Argo CD에 등록하여 액세스 권한을 제공합니다:

```bash
$ export GITEA_SSH_HOSTNAME=$(kubectl get svc -n gitea gitea-ssh -o jsonpath="{.status.loadBalancer.ingress[*].hostname}")
$ argocd repo add ssh://git@${GITEA_SSH_HOSTNAME}:2222/workshop-user/argocd.git \
  --ssh-private-key-path ${HOME}/.ssh/gitops_ssh.pem \
  --insecure-ignore-host-key --upsert --name git-repo
Repository 'ssh://...' added
```

