---
title: "Updating an application"
sidebar_position: 20
---

Now we can use Argo CD and Kustomize to deploy patches to our application manifests using GitOps
For example, lets increase the number of `replicas` for `ui` deployment to `3`

```kustomization
automation/gitops/argocd-codecommit/update-application/deployment-patch.yaml
Deployment/ui
```

Copy patch file to the Git repository directory:

```bash
$ cp /workspace/modules/automation/gitops/argocd-codecommit/update-application/deployment-patch.yaml ~/environment/gitops/apps/deployment-patch.yaml
```

You can review planned changes in the file `/gitops/apps/deployment-patch.yaml`

To apply the patch edit the file `/gitops/apps/kustomization.yaml` like in the example below:

```file
automation/gitops/argocd-codecommit/update-application/kustomization.yaml
```

You can execute commands to add necessary changes to the file `/gitops/apps/kustomization.yaml`:

```bash
$ echo "patches:" >> ~/environment/gitops/apps/kustomization.yaml
$ echo "- deployment-patch.yaml" >> ~/environment/gitops/apps/kustomization.yaml
```

Push changes to CodeCommit

```bash
$ (cd ~/environment/gitops && \
git add . && \
git commit -am "Update UI service replicas" && \
git push)
```

Go to Argo CD UI, `Sync` and `Refresh` and you should now have all the changes the UI services deployed once more. To verify, run the following commands:

```bash
$ kubectl get deployment -n ui ui
NAME   READY   UP-TO-DATE   AVAILABLE   AGE
ui     3/3     3            3           14m
$ kubectl get pod -n ui
NAME                  READY   STATUS    RESTARTS   AGE
ui-6d5bb7b95-4b8wr   1/1     Running   0          10m
ui-6d5bb7b95-dtzvl   1/1     Running   0          14m
ui-6d5bb7b95-t7jrf   1/1     Running   0          9s
```
