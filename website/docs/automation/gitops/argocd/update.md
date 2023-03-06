---
title: "Updating the application"
sidebar_position: 20
---

During the development lifecycle, there are new container images or the development team may want to change the configuration of the application. You need to update the application to reflect the latest changes following the GitOps workflow.

In this lab excerise, we'll update the `catalog` application to increase replicas to handle higher traffic with Argo CD. 

Update replicas of the `catalog` application in the `kuztomization` file to 3:

```file
automation/gitops/argocd/update-app/kustomization.yaml
```

:::tip In your environment
You should update the same `kustomization.yaml` file and commit to the Git repository.
:::
Update Argo CD app to reflect the latest changes:

```bash
$ argocd app set argocd-demo --path environment/workspace/modules/automation/gitops/argocd/update-app
``` 

Flip back to the ArGo CD UI and you should see the application is in `OutOfSync` state.

<img src={require('./assets/argocd-ui-outofsync.png').default}/>

Click on the `Sync` button to sync the application with the latest changes.

After a few seconds, you should see the application is in `Synced` state. Your application is now updated with the latest changes and the replicas is increased to 3.

<img src={require('./assets/argocd-ui-synced.png').default}/>

We're now successfully updated the application with the latest changes using Argo CD and GitOps workflow.