---
title: 'Continuous Integration and GitOps'
sidebar_position: 50
---

We have successfully bootstrapped Flux on our cluster so now we can deploy an application. To demonstrate how to make changes in the source code and leverage GitOps to deploy a new image to a cluster we introduce Continuous Integration pipeline.

Next, clone the repository for the application sources:

```bash
$ git clone ssh://${GITOPS_IAM_SSH_KEY_ID}@git-codecommit.${AWS_REGION}.amazonaws.com/v1/repos/${EKS_CLUSTER_NAME}-retail-store-sample ~/environment/retail-store-sample-codecommit
```

```bash
$ git clone https://github.com/aws-containers/retail-store-sample-app ~/environment/retail-store-sample-app

$ git -C ~/environment/retail-store-sample-codecommit checkout -b main

$ cp -R retail-store-sample-app/src retail-store-sample-codecommit
$ cp -R retail-store-sample-app/scripts retail-store-sample-codecommit
$ cp -R retail-store-sample-app/images retail-store-sample-codecommit
```

```bash
$ cp ~/environment/eks-workshop/modules/automation/gitops/flux/buildspec.yml ~/environment/retail-store-sample-codecommit/buildspec.yml
```

```bash
$ git -C ~/environment/retail-store-sample-codecommit add .
$ git -C ~/environment/retail-store-sample-codecommit commit -am "initial commit"
$ git -C ~/environment/retail-store-sample-codecommit push --set-upstream origin main
```

As a result of a CodePipeline run with CodeBuild you will have a new image in ECR

```bash
$ flux install --components-extra=image-reflector-controller,image-automation-controller
```
Edit file
```bash
$ vi ~/environment/flux/apps/ui/deployment.yaml
```

Change

image: "public.ecr.aws/aws-containers/retail-store-sample-ui:0.4.0" `# {"$imagepolicy": "flux-system:ui"}`

```bash
$ git -C ~/environment/flux add .
$ git -C ~/environment/flux commit -am "Adding ImagePolicy"
$ git -C ~/environment/flux push
```

```bash
$ cat <<EOF | envsubst | kubectl create -f -
apiVersion: image.toolkit.fluxcd.io/v1beta2
kind: ImageRepository
metadata:
  name: ui
  namespace: flux-system
spec:
  provider: aws
  interval: 1m
  image: ${IMAGE_URI_UI}
  accessFrom:
    namespaceSelectors:
      - matchLabels:
          kubernetes.io/metadata.name: flux-system
EOF
imagerepository.image.toolkit.fluxcd.io/ui created
```

```bash
$ cat <<EOF | kubectl create -f -
apiVersion: image.toolkit.fluxcd.io/v1beta2
kind: ImagePolicy
metadata:
  name: ui
  namespace: flux-system
spec:
  imageRepositoryRef:
    name: ui
  filterTags:
    pattern: '^i[a-fA-F0-9]'
  policy:
    alphabetical:
      order: asc
EOF
imagepolicy.image.toolkit.fluxcd.io/ui created
```

```bash
$ cat <<EOF | kubectl create -f -
apiVersion: image.toolkit.fluxcd.io/v1beta1
kind: ImageUpdateAutomation
metadata:
  name: ui
  namespace: flux-system
spec:
  git:
    checkout:
      ref:
        branch: main
    commit:
      author:
        email: fluxcdbot@users.noreply.github.com
        name: fluxcdbot
      messageTemplate: '{{range .Updated.Images}}{{println .}}{{end}}'
    push:
      branch: main
  interval: 1m0s
  sourceRef:
    kind: GitRepository
    name: flux-system
    namespace: flux-system
  update:
    path: ./apps
    strategy: Setters
EOF
imageupdateautomation.image.toolkit.fluxcd.io/ui created
```

```bash
$ flux reconcile image repository ui
$ flux reconcile source git flux-system
$ flux reconcile kustomization apps
$ kubectl wait deployment -n ui ui --for condition=Available=True --timeout=120s
$ git -C ~/environment/flux pull
$ kubectl -n ui get pods
```

```bash
$ kubectl -n ui describe deployment ui | grep Image
```

Let's create an Ingress resource with the following manifest:

```file
manifests/modules/exposing/ingress/creating-ingress/ingress.yaml
```

This will cause the AWS Load Balancer Controller to provision an Application Load Balancer and configure it to route traffic to the Pods for the `ui` application.

```bash timeout=180 hook=add-ingress hookTimeout=430
$ kubectl apply -k ~/environment/eks-workshop/modules/exposing/ingress/creating-ingress
```

Let's inspect the Ingress object created:

```bash
$ kubectl get ingress ui -n ui
NAME   CLASS   HOSTS   ADDRESS                                            PORTS   AGE
ui     alb     *       k8s-ui-ui-1268651632.us-west-2.elb.amazonaws.com   80      15s
```

Check the UI page using url of the ingress

```bash
$ export UI_URL=$(kubectl get ingress -n ui ui -o jsonpath="{.status.loadBalancer.ingress[*].hostname}{'\n'}")
$ curl $UI_URL/home | grep "Retail Store Sample"
```

Edit file
```bash
$ vi ~/environment/retail-store-sample-codecommit/src/ui/src/main/resources/templates/fragments/layout.html
```

Change

`<a class="navbar-brand" href="/home">Retail Store Sample</a>` to `<a class="navbar-brand" href="/home">Retail Store Sample New</a>`

```bash
$ git -C ~/environment/retail-store-sample-codecommit status
$ git -C ~/environment/retail-store-sample-codecommit add .
$ git -C ~/environment/retail-store-sample-codecommit commit -am "Update UI src"
$ git -C ~/environment/retail-store-sample-codecommit push
```

Wait until CI will build the new image and Flux will deploy it

```bash
$ kubectl -n ui describe deployment ui | grep Image
$ aws codepipeline start-pipeline-execution --name eks-workshop-retail-store-sample
$ sleep 10
$ while [[ "$(aws codepipeline get-pipeline-state --name eks-workshop-retail-store-sample --query 'stageStates[1].actionStates[0].latestExecution.status' --output text)" != "Succeeded" ]]; do echo "Waiting for pipeline to reach 'Succeeded' state..."; sleep 10; done && echo "Pipeline has reached the 'Succeeded' state."

$ flux reconcile image repository ui
$ sleep 5
$ flux reconcile source git flux-system
$ flux reconcile kustomization apps
$ kubectl wait deployment -n ui ui --for condition=Available=True --timeout=120s
$ git -C ~/environment/flux pull
$ kubectl -n ui get pods

$ kubectl -n ui describe deployment ui | grep Image

$ export UI_URL=$(kubectl get ingress -n ui ui -o jsonpath="{.status.loadBalancer.ingress[*].hostname}{'\n'}")
$ while [[ $(curl -s -o /dev/null -w "%{http_code}" $UI_URL/home) != "200" ]]; do sleep 1; done
$ curl $UI_URL/home | grep "Retail Store Sample"
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