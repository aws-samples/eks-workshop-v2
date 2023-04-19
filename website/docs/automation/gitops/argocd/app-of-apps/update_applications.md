---
title: "Updating applications"
sidebar_position: 70
---

Now we can use Argo CD and Kustomize to deploy patches to our application manifests using GitOps. For example, lets increase the number of `replicas` for `ui` deployment to `3`.

You can execute commands to add necessary changes to the file `apps-kustomization/ui/deployment-patch.yaml`:

```bash
$ yq -i '.spec.replicas = 3' ~/environment/argocd/apps-kustomization/ui/deployment-patch.yaml
```

You can review planned changes in the file `apps-kustomization/ui/deployment-patch.yaml`.

```kustomization
automation/gitops/argocd/update-application/deployment-patch.yaml
Deployment/ui
```

Push changes to the Git repository:

```bash
$ git -C ~/environment/argocd add .
$ git -C ~/environment/argocd commit -am "Update UI service replicas"
$ git -C ~/environment/argocd push
```

Go to Argo CD UI, wait about 5s or hit `Refresh`/`Sync` and you should now have all the changes to the UI services deployed once more.
We should have now 3 pods in `ui` deployment.

![argocd-update-application](../assets/argocd-update-application.png)

To verify, run the following commands:

```bash hook=update
$ kubectl get deployment -n ui ui
NAME   READY   UP-TO-DATE   AVAILABLE   AGE
ui     3/3     3            3           3m33s
$ kubectl get pod -n ui
NAME                  READY   STATUS    RESTARTS   AGE
ui-6d5bb7b95-hzmgp   1/1     Running   0          61s
ui-6d5bb7b95-j28ww   1/1     Running   0          61s
ui-6d5bb7b95-rjfxd   1/1     Running   0          3m34s
```
