---
title: "Deploying an application"
sidebar_position: 15
---

We have successfully bootstrapped Flux on our cluster so now we can deploy an application. To demonstrate the difference between a GitOps-based delivery of an application and other methods, we'll migrate the UI component of the sample application which is currently using the `kubectl apply -k` approach to the new Flux deployment approach.

First let's remove the existing UI component so we can replace it:

```bash
$ kubectl delete namespace ui
```

Next, clone the repository we used to bootstrap Flux in the previous section:

```bash
$ git clone ssh://${GITOPS_IAM_SSH_KEY_ID}@git-codecommit.${AWS_REGION}.amazonaws.com/v1/repos/${EKS_CLUSTER_NAME}-gitops ~/environment/flux
```

Now, let's start populating the Flux repository by creating a directory for our "apps". This directory is designed to contain a sub-directory for each application component:

```bash
$ mkdir ~/environment/flux/apps
```

Then create a kustomization that lets Flux know about that directory:

::yaml{file="manifests/modules/automation/gitops/flux/basic/apps.yaml" paths="metadata.name,spec.interval,spec.path"}

1. Give the kustomization a recognizable name
2. Tell Flux to poll this every minute
3. Use the `apps` path in the Git repository

Copy this file to the Git repository directory:

```bash
$ cp ~/environment/eks-workshop/modules/automation/gitops/flux/basic/apps.yaml \
  ~/environment/flux/apps.yaml
```

We'll be installing the application components using their Helm charts, which are published to [Amazon ECR Public](https://gallery.ecr.aws/).

Let's create a HelmRepository resource to tell Flux where to source our charts:

::yaml{file="manifests/modules/automation/gitops/flux/basic/apps/repository.yaml" paths="spec.url,spec.type,spec.interval"}

1. The URL of the Helm repository
2. ECR Public hosts Helm charts as OCI artifacts
3. Check for updates every 5 minutes

Copy this file to the Git repository directory:

```bash
$ cp ~/environment/eks-workshop/modules/automation/gitops/flux/basic/apps/repository.yaml \
  ~/environment/flux/apps/repository.yaml
```

Finally we'll tell Flux to install the Helm chart for the ui component:

::yaml{file="manifests/modules/automation/gitops/flux/basic/apps/ui/helm.yaml" paths="metadata.name,spec.chart,spec.install.createNamespace,spec.values"}

1. The name of the HelmRelease resource
2. The name and version of the chart to install, referencing the Helm repository we specified above
3. Create the namespace if it doesn't exist
4. Configure the chart using `values`, in this case enabling ingress

Copy the appropriate files to the Git repository directory:

```bash
$ cp -R ~/environment/eks-workshop/modules/automation/gitops/flux/basic/apps/ui \
  ~/environment/flux/apps
```

You Git directory should now look something like this which you can validate by running `tree ~/environment/flux`:

```text
.
├── apps
│   ├── kustomization.yaml
│   └── ui
│       ├── helm.yaml
│       └── kustomization.yaml
├── apps.yaml
└── flux-system
    ├── gotk-components.yaml
    ├── gotk-sync.yaml
    └── kustomization.yaml


3 directories, 7 files
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

Get the URL from the Ingress resource:

```bash
$ kubectl get ingress -n ui ui -o jsonpath="{.status.loadBalancer.ingress[*].hostname}{'\n'}"
k8s-ui-uinlb-a9797f0f61.elb.us-west-2.amazonaws.com
```

To wait until the load balancer has finished provisioning you can run this command:

```bash
$ wait-for-lb $(kubectl get ingress -n ui ui -o jsonpath="{.status.loadBalancer.ingress[*].hostname}{'\n'}")
```

And access it in your web browser. You will see the UI from the web store displayed and will be able to navigate around the site as a user.

<Browser url="http://k8s-ui-ui-a9797f0f61.elb.us-west-2.amazonaws.com">
<img src={require('@site/static/img/sample-app-screens/home.webp').default}/>
</Browser>
