---
title: 'Deploying an application'
sidebar_position: 15
---

We have successfully bootstrapped Flux on our cluster so now we can deploy an application. To demonstrate the difference between a GitOps-based delivery of an application and other methods, we'll migrate the UI component of the sample application which is currently using the `kubectl apply -k` approach to the new Flux deployment approach.

First let's remove the existing UI component so we can replace it:

```bash
$ kubectl delete -k ~/environment/eks-workshop/base-application/ui
```

Next, clone the repository we used to bootstrap Flux in the previous section:

```bash
$ git clone ssh://${GITOPS_IAM_SSH_KEY_ID}@git-codecommit.${AWS_REGION}.amazonaws.com/v1/repos/${EKS_CLUSTER_NAME}-gitops ~/environment/flux
```

Now, let's get into the cloned repository and start creating our GitOps configuration. Copy the existing kustomize configuration for the UI service:

```bash
$ mkdir ~/environment/flux/apps
$ cp -R ~/environment/eks-workshop/base-application/ui ~/environment/flux/apps
```

We'll then need to create a kustomization in the `apps` directory:

```file
manifests/modules/automation/gitops/flux/apps-kustomization.yaml
```

Copy this file to the Git repository directory:

```bash
$ cp ~/environment/eks-workshop/modules/automation/gitops/flux/apps-kustomization.yaml \
  ~/environment/flux/apps/kustomization.yaml
```

The last step before we push our changes is to ensure that Flux is aware of our `apps` directory. We do that by creating an additional file in the `flux` directory:

```file
manifests/modules/automation/gitops/flux/flux-kustomization.yaml
```

Copy this file to the Git repository directory:

```bash
$ cp ~/environment/eks-workshop/modules/automation/gitops/flux/flux-kustomization.yaml \
  ~/environment/flux/apps.yaml
```

You Git directory should now look something like this which you can validate by running `tree ~/environment/flux`:

```
.
├── apps
│   ├── kustomization.yaml
│   └── ui
│       ├── configMap.yaml
│       ├── deployment.yaml
│       ├── kustomization.yaml
│       ├── namespace.yaml
│       ├── serviceAccount.yaml
│       └── service.yaml
├── apps.yaml
└── flux-system
    ├── gotk-components.yaml
    ├── gotk-sync.yaml
    └── kustomization.yaml


3 directories, 11 files
```

Finally we can push our configuration to CodeCommit:

```bash
$ git -C ~/environment/flux add .
$ git -C ~/environment/flux commit -am "Adding the UI service"
$ git -C ~/environment/flux push origin main
```

It will take Flux some time to notice the changes in CodeCommit and reconcile. You can use the Flux CLI to watch for our new `apps` kustomization to appear:

```bash test=false
$ flux get kustomization --watch
NAMESPACE     NAME          AGE   READY   STATUS
flux-system   flux-system   14h   True    Applied revision: main/f39f67e6fb870eed5997c65a58c35f8a58515969
flux-system   apps          34s   True    Applied revision: main/f39f67e6fb870eed5997c65a58c35f8a58515969
```

You can also manually trigger Flux to reconcile like so:

```bash wait=30 hook=flux-deployment
$ flux reconcile source git flux-system -n flux-system
```

Once `apps` appears as indicated above use `Ctrl+C` to close the command. You should now have all the resources related to the UI services deployed once more. To verify, run the following commands:

```bash
$ kubectl get deployment -n ui ui
NAME   READY   UP-TO-DATE   AVAILABLE   AGE
ui     1/1     1            1           5m
$ kubectl get pod -n ui
NAME                  READY   STATUS    RESTARTS   AGE
ui-54ff78779b-qnrrc   1/1     Running   0          5m
```

We've now successfully migrated the UI component to deploy using Flux, and any further changes pushed to the Git repository will be automatically reconciled to our EKS cluster.
