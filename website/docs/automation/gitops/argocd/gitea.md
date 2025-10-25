---
title: "Setting up Gitea"
sidebar_position: 5
---

We'll be using [Gitea](https://gitea.com) as a quick and easy alternative to GitHub or GitLab. Gitea is a lightweight, self-hosted Git service that provides a user-friendly web interface, allowing us to rapidly set up and manage our own Git repositories. This will serve as our source of truth for storing and versioning our Kubernetes manifests, which is essential for the GitOps workflows we'll be exploring with Argo CD.

Let's install Gitea in our EKS cluster with Helm:

```bash
$ helm upgrade --install gitea oci://docker.gitea.com/charts/gitea \
  --version "$GITEA_CHART_VERSION" \
  --namespace gitea --create-namespace \
  --values ~/environment/eks-workshop/modules/automation/gitops/argocd/gitea/values.yaml \
  --set "gitea.admin.password=${GITEA_PASSWORD}" \
  --wait
```

Make sure that Gitea is up and running before proceeding:

```bash timeout=300
$ export GITEA_HOSTNAME=$(kubectl get svc -n gitea gitea-http -o jsonpath="{.status.loadBalancer.ingress[*].hostname}")
$ curl --head -X GET --retry 30 --retry-all-errors --retry-delay 15 \
  --connect-timeout 10 --max-time 60 \
  http://${GITEA_HOSTNAME}:3000
```

An SSH key will be needed to interact with Git. The environment preparation for this lab created one, we just need to register it with Gitea:

```bash
$ curl -X 'POST' \
  "http://workshop-user:$GITEA_PASSWORD@${GITEA_HOSTNAME}:3000/api/v1/user/keys" \
  -H 'accept: application/json' \
  -H 'Content-Type: application/json' \
  -d "{\"key\": \"$SSH_PUBLIC_KEY\",\"read_only\": true,\"title\": \"gitops\"}"
```

And we'll also need to create the Gitea repository that Argo CD will use:

```bash
$ curl -X 'POST' \
  "http://workshop-user:$GITEA_PASSWORD@${GITEA_HOSTNAME}:3000/api/v1/user/repos" \
  -H 'accept: application/json' \
  -H 'Content-Type: application/json' \
  -d "{\"name\": \"argocd\"}"
```

Now we can set up an identity that Git will use for our commits:

```bash
$ git config --global user.email "you@eksworkshop.com"
$ git config --global user.name "Your Name"
$ git config --global init.defaultBranch main
$ git config --global core.sshCommand 'ssh -i ~/.ssh/gitops_ssh.pem'
```

And finally let's clone the repository and set up the initial structure:

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
