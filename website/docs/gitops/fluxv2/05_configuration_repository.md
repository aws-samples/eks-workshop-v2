---
title: 'GitOps the UI service'
sidebar_position: 15
---

After we have successfully bootstrap flux on our cluster, and have flux create a new configuration repository for us, we will now deploy an application using Flux.
To demonstrate the difference between GitOps based a delivery of an application and other method, we will use the already deployed UI service that you deployed when you started this workshop.

The reason we chose the UI service, is because it can be easily replicated in the cluster into a new namespace, while relying on all other backend services that were deployed when setting up the environment of this workshop.

# Clone the GitOps configuration repository

First you will have to clone the repository created by Flux in the previous section. Using this repository we will deploy the replicated UI service that will be deployed by Flux.

```bash test=false
$ git clone https://github.com/$GITHUB_USER/eksworkshop-gitops-config-flux.git
```

Now we can get into the cloned repository, and start creating our GitOps configuration.

# Create your base application configuration for the UI service

Using the cloned repository, you are now able to define application manifests, either by using plain Kubernetes manifests, kustomizations, or helm chart. Before we'll get into that, we first have to think about how to structure our configuration repository. The structure will have impplication on who will need to have access to this repository, as well on how application configurations and manifests will be hosted in this repository. Flux documentation describes multiple options for structuring a configuration repository/ies. If you're considereing of deploying multiple applications and teams on a single cluster, you might want to seperate them into a Repository per Appplication or per Team to seperate the permissions each application team have to its configuration repository. The [`flux-eks-gitops-config`](https://github.com/aws-samples/flux-eks-gitops-config) sample demonstrate that, by having a shared repository for all cluster's platform level services, such as: metrics-server, nginx-ingress-controller, prometheus, etc...

For simplicity, we will use the monorepo approach, where all application manifests will be hosted in a single repository. As described in the Flux documentation, our repository structure will look somewhat like this:

```
├── apps
│   ├── base
│   ├── production
│   └── staging
├── infrastructure
│   ├── base
│   ├── production
│   └── staging
└── clusters
    ├── production
    └── staging
```

Let's start with structuring our deployment configuration.
First, we will create an application base folder for our deployment, and copy the content of the UI service manifest folder to our base app. We will use this as a base configuration that will be customized (with Kustomize) between environemtns.

```bash
$ mkdir -p eksworkshop-gitops-config-flux/app/base/ui && \
mkdir -p eksworkshop-gitops-config-flux/app/production/ui && \
cp -r ./workspace/manifests/ui/ ./eksworkshop-gitops-config-flux/app/base/ui/
```

Next, we will add a Kustomization file to specifiy which files needs to be applied when pointing this folder

```bash
$ cat <<EOF >>./eksworkshop-gitops-config-flux/app/base/ui/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - configMap.yaml
  - deployment.yaml
  - namespace.yaml
  - service.yaml
  - serviceAccount.yaml
EOF
```

All we have to do now, is to create another kustomization overlay to represent our new ui service that will be deployed the GitOps way using Flux. You can read more about [Kustomizations Bases and Overlays](https://kubernetes.io/docs/tasks/manage-kubernetes-objects/kustomization/#bases-and-overlays) in Kubernetes documentation. Remember that we are using the same UI service manifests to point to the already deployed backend services. Therfore, to avoid clashes between the already deployed `UI` service, we will kustomize the base folder to deploy to a new namespace that we will call `ui-gitops`. We will also configured the Kubernetes service to be of a type `LoadBalancer`, in order to instruct Kubernetes to generate Load-Balancer for this service

```bash
$ cat <<EOF >>./eksworkshop-gitops-config-flux/app/production/ui/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: ui-gitops
resources:
  - ../../base/ui
patches:
  - path: ui-values.yaml
    options:
      allowNameChange: true
EOF

$ cat <<EOF >>./eksworkshop-gitops-config-flux/app/production/ui/ui-values.yaml
apiVersion: v1
kind: Service
metadata:
  name: ui
spec:
  type: LoadBalancer
EOF
```

# Configure Flux toolkit to point to the `UI` service kustomization

Up until now, we configured how our newly `UI` service will be configured and deployed by Flux.
What's left to do now, is to configure Flux that already been bootstrapped to the cluster, to point to our new `UI` service.

Before we'll guide you through on how to do that, can you try and figure out what configurations needs to be made to add the new `UI` service to the Flux configuration?
You can use the guidance in [Flux documentation](https://fluxcd.io/flux/get-started/#add-podinfo-repository-to-flux) as a starting point, even though the implementation here is a bit different as we're hosting the application deployment manifests, inside the flux configuration repository, and not as a standalone application repository

<details><summary>Explain me how</summary>
<p>

To point Flux configuration to the `UI` service kustomization, we will have to add a Flux Kustomization configuration (not to be confused with Kubernetes Kustomization described previously).
[Flux Kustomization](https://fluxcd.io/flux/components/kustomize/kustomization/) defines the source to fetch from, the reconciliation interval, and the target namespace. The source to fetch from can be any object configured by Flux [Source Controller](https://fluxcd.io/flux/components/source/). The flux bootstrap process automatically generates a source git repository with the name of `flux-system` that points to our newly created repository ( the `eksworkshop-gitops-config-flux` that was created earlier). Thise GitRepository is configured under the path of `./eksworkshop-gitops-config-flux/clusters/production/flux-system/gotk-sync.yaml`. The content of this file looks like this:

```yaml
---
apiVersion: source.toolkit.fluxcd.io/v1beta2
kind: GitRepository
metadata:
  name: flux-system
  namespace: flux-system
spec:
  interval: 1m0s
  ref:
    branch: main
  secretRef:
    name: flux-system
  url: ssh://git@github.com/aws-samples/eksworkshop-gitops-config-flux
---
apiVersion: kustomize.toolkit.fluxcd.io/v1beta2
kind: Kustomization
metadata:
  name: flux-system
  namespace: flux-system
spec:
  interval: 10m0s
  path: ./clusters/production
  prune: true
  sourceRef:
    kind: GitRepository
    name: flux-system
```

As you can see in the above snippet, the `GitRepository` named `flux-system` that is deployed in the namespace `flux-system`, points to the newly generated git repository.

Since we are using the monorepo approach in this workshop module, we can simply point out Flux kustomization to use the configured Flux `GitRepository` object, and retrieve our new `UI` service manifests from it (Remember - we are hosting both the Flux toolkit configuration and the application manifests configuration in the same repository). To create it, use the following command:

```bash
$ cat <<EOF >>./eksworkshop-gitops-config-flux/clusters/production/ui-kustomization.yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1beta2
kind: Kustomization
metadata:
  name: ui
  namespace: flux-system
spec:
  interval: 5m0s
  path: ./app/production/ui
  prune: true
  sourceRef:
    kind: GitRepository
    name: flux-system
EOF
```

The important configuration in the above kustomization file is the `path` and the `name` of the `GitRepository`. Pay attention ot the path within this repository, which reflects the kustomization overlay you've defined above on the base `UI` service manifests. Remember: the only changed we made is to override the `namespace` been used, and the `serviceType` of the Kuberntes service of the `UI`

</p>
</details>

# Commit and Push your changes

After you configured Flux to point to your GitOps version of the `UI` service, then the final step is to commit & push all the configurations we have created up until now.
Within the cloned repository of `eksworkshop-gitops-config-flux`, run the following command

```bash
$ cd eksworkshop-gitops-config-flux && \
git add . && \
git commit -am "Configuring the UI service" && \
git push origin main
```

# Verify the delivery of the `UI` service

Assuming everything worked as expected, you now should have the following components in your cluster:

- A new namespace named `ui-gitops`
- A complete deployment of the `UI` service into the `ui-gitops` namespace
- A modified Kubernetes service of type `LoadBalancer` in the `ui-gitops` namespace

To verify your `UI` service kustomization was successfully created, you will need to use the flux CLI. Can you figure out what command it should be based on Flux [documentation](https://fluxcd.io/flux/components/kustomize/kustomization/)?

<details><summary>Show me the command</summary>
<p>

```bash
$ flux get kustomization
```

</p>
</details>

You should be able to retrieve the modified `LoadBalancer` service endpoint from the `ui-gitops` namespce. Get the endpoint and head over to your browseer to make sure the new `UI` service is accessible from that endpoint
