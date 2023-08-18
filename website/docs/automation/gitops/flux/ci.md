---
title: 'Continuous Integration and GitOps'
sidebar_position: 50
---

We have successfully bootstrapped Flux on our cluster so now we can deploy an application. To demonstrate how to make changes in the source code and leverage GitOps to deploy a new image to a cluster we introduce Continuous Integration pipeline.

Next, clone the repository for the application sources:

```bash
$ git clone ssh://${GITOPS_IAM_SSH_KEY_ID}@git-codecommit.${AWS_REGION}.amazonaws.com/v1/repos/${EKS_CLUSTER_NAME}-retail-store-sample ~/environment/retail-store-sample-codecommit

$ git clone https://github.com/aws-containers/retail-store-sample-app

$ git -C ~/environment/retail-store-sample-codecommit checkout -b main

$ cp -R retail-store-sample-app/src retail-store-sample-codecommit
$ cp -R retail-store-sample-app/scripts retail-store-sample-codecommit
$ cp -R retail-store-sample-app/images retail-store-sample-codecommit

$ cp ~/environment/eks-workshop/modules/automation/gitops/flux/buildspec.yml ~/environment/retail-store-sample-codecommit/buildspec.yml

$ cd ~/environment/retail-store-sample-codecommit/

$ git config --global user.email "you@example.com"
$ git config --global user.name "Your Name"

$ git -C ~/environment/retail-store-sample-codecommit add .
$ git -C ~/environment/retail-store-sample-codecommit commit -am "initial commit"
$ git -C ~/environment/retail-store-sample-codecommit push --set-upstream origin main

```

As a result of a CodePipeline run with CodeBuild you will have a new image in ECR

```bash
$ flux install --components-extra=image-reflector-controller,image-automation-controller
```

Work in progress ...

-------

<!-- First let's remove the existing UI component so we can replace it:

```bash
$ kubectl delete -k /workspace/manifests/ui
```

Next, clone the repository we used to bootstrap Flux in the previous section:

```bash
$ git clone ssh://${GITOPS_IAM_SSH_KEY_ID}@git-codecommit.${AWS_DEFAULT_REGION}.amazonaws.com/v1/repos/${EKS_CLUSTER_NAME}-gitops ~/environment/gitops
```

Now, let's get into the cloned repository and start creating our GitOps configuration. Copy the existing kustomize configuration for the UI service:

```bash
$ mkdir ~/environment/gitops/apps
$ cp -R /workspace/manifests/ui ~/environment/gitops/apps
```

We'll then need to create a kustomization in the `apps` directory:



Copy this file to the Git repository directory:

```bash
$ cp /workspace/modules/automation/gitops/flux/apps-kustomization.yaml ~/environment/gitops/apps/kustomization.yaml
```

The last step before we push our changes is to ensure that Flux is aware of our `apps` directory. We do that by creating an additional file in the `flux` directory:


Copy this file to the Git repository directory:

```bash
$ cp /workspace/modules/automation/gitops/flux/flux-kustomization.yaml ~/environment/gitops/apps.yaml
```

You Git directory should now look something like this which you can validate by running `tree ~/environment/gitops`:

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
$ (cd ~/environment/gitops && \
git add . && \
git commit -am "Adding the UI service" && \
git push origin main)
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

We've now successfully migrated the UI component to deploy using Flux, and any further changes pushed to the Git repository will be automatically reconciled to our EKS cluster. -->