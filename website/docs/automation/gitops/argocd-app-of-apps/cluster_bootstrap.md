---
title: "Cluster bootstrap"
sidebar_position: 15
---

An AWS CodeCommit repository has already been created for you and Argo CD has already been deployed to the EKS cluster so let's create necessary Argo CD components for our application.

<!-- Create an Argo CD `Application`:

```file
automation/gitops/argocd-codecommit/application/application.yaml
```

Let's break down the manifest above:

- First we tell ArgoCD what will be the `name` of our application
- After that we define which Git repository `source` to use to get the desired state of our application. We define `repoUrl` of the AWS CodeCommit repository, a repository branch with `targetRevision`
- Finally we define a `path` to application manifests within the repository -->

<!-- Copy the existing kustomize configuration for the Argo CD application: -->

<!-- ```bash
$ mkdir -p ~/environment/argocd-application
$ cp -R /workspace/modules/automation/gitops/argocd-codecommit/application/* ~/environment/argocd-application
``` -->

<!-- Let's apply the kustomization: -->

First, clone the CodeCommit repository:

```bash
$ export GITOPS_REPO_URL=ssh://${GITOPS_IAM_SSH_KEY_ID}@git-codecommit.${AWS_DEFAULT_REGION}.amazonaws.com/v1/repos/${EKS_CLUSTER_NAME}-gitops-argocd
$ git clone ${GITOPS_REPO_URL} ~/environment/gitops-argocd
$ cd ~/environment/gitops-argocd && git checkout -b main && cd ..
Switched to a new branch 'main'
```

Create an Argo CD repository `Secret` to store `sshPrivateKey` for access to an AWS Codecommit repository `url`:

```bash
$ kubectl -n argocd delete secret codecommit-repo --ignore-not-found && \
kubectl -n argocd create secret generic codecommit-repo \
--from-literal=type=git \
--from-literal=insecure="true" \
--from-literal=url="${GITOPS_REPO_URL}" \
--from-file=sshPrivateKey=${HOME}/.ssh/gitops_ssh.pem \
&& kubectl -n argocd label secret codecommit-repo "argocd.argoproj.io/secret-type=repository"
secret/codecommit-repo created
secret/codecommit-repo labeled
```

```bash
$ cp -R /workspace/modules/automation/gitops/argocd-app-of-apps/apps-config ~/environment/gitops-argocd/
$ yq -i '.spec.source.repoURL = strenv(GITOPS_REPO_URL)' ~/environment/gitops-argocd/apps-config/values.yaml
$ cp -R /workspace/modules/automation/gitops/argocd-app-of-apps/apps-kustomization ~/environment/gitops-argocd/
```

```bash
$ cp -R /workspace/modules/automation/gitops/argocd-app-of-apps/app ~/environment/gitops-argocd/
$ echo $GITOPS_REPO_URL > ~/environment/gitops-argocd/app/gitops_repo_url
```

```bash
$ (cd ~/environment/gitops-argocd && \
git add . && \
git commit -am "Adding the App of Apps configs and kustomizations" && \
git push --set-upstream origin main)
```

Get Argo CD UI url and `admin` password

```bash
$ echo "ArgoCD URL: http://$(kubectl get svc argocd-server -n argocd -o json | jq --raw-output '.status.loadBalancer.ingress[0].hostname')"
$ echo "ArgoCD admin password: $(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)"
```

Now, let's get into the cloned repository and start creating our GitOps configuration. Copy the existing configuration for the App of Apps application:

```bash
$ kubectl apply -k ~/environment/gitops-argocd/app
application.argoproj.io/apps created
```
