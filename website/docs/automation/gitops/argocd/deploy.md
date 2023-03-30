---
title: "Deploying an application"
sidebar_position: 15
---

Argo CD applies the `GitOps` methodology to Kubernetes. It uses Git as a source of truth for your cluster's desired state. You can use Argo CD to deploy applications, monitor their health, and sync them with the desired state. Kubernetes manifests can be specified in several ways:
* Kustomize applications
* Helm charts
* Jsonnet files
* Plain directories of Kubernetes YAML files

In this lab exercise, we'll deploy a simple applications specified in Kustomize using Argo CD. We'll use the `catalog` application from our [EKS Workshop](https://github.com/aws-samples/eks-workshop-v2) repository.

## Create an Argo CD Application

Argo CD application is a CRD Kubernetes resource object representing a deployed application instance in an environment. It defines key information about the application, such as the application name, the Git repository, and the path to the Kubernetes manifests. The application resource also defines the desired state of the application, such as the target revision, the sync policy, and the health check policy.

Let's create a namespace for our application:

```bash
$ kubectl create ns argocd-demo
```

Create an Argo CD application:

```bash
$ argocd app create argocd-demo --repo https://github.com/aws-samples/eks-workshop-v2.git --path environment/workspace/modules/automation/gitops/argocd --dest-server https://kubernetes.default.svc --dest-namespace argocd-demo
 application 'argocd-demo' created
```

Verify that the application has been created:

```bash
$ argocd app list
NAME                CLUSTER                         NAMESPACE    PROJECT  STATUS     HEALTH   SYNCPOLICY  CONDITIONS  REPO                                                PATH                                                    TARGET
argocd/argocd-demo  https://kubernetes.default.svc  argocd-demo  default  OutOfSync  Healthy  <none>      <none>      https://github.com/aws-samples/eks-workshop-v2.git  environment/workspace/modules/automation/gitops/argocd
```

Alternatively, you can also intereact with Argo CD objects in the cluster using the `kubectl` command:

```bash
$ kubectl get apps -n argocd
NAME          SYNC STATUS   HEALTH STATUS
argocd-demo   OutOfSync     Missing
```

Open the Argo CD UI and navigate to the `argocd-demo` application. You should see the following screen:

<img src={require('./assets/argocd-app.png').default}/>

Notice that the application is currently in `OutOfSync` state. This means that the application is not deployed and in sync with the desired state. 

Let's check if there are any pods running in the `argocd-demo` namespace:

```bash
$ kubectl get pods -n argocd-demo
No resources found in argocd-demo namespace.
```

Now, we're going to `sync` the application. This will deploy the application to the cluster and bring it to the desired state.

Click on the `SYNC` button in the UI of the app. 

<img src={require('./assets/argocd-sync.png').default}/>

Or, you can also use the `argocd` CLI:

```bash
$ argocd app sync argocd-demo
```

After a short period of time, the application should be in `Synced` state and the resources should be deployed, the UI should look like this:

<img src={require('./assets/argocd-synced.png').default}/>

Let's check if resources have been deployed:

```bash
$ kubectl get all -n argocd-demo
NAME                           READY   STATUS    RESTARTS        AGE
pod/catalog-6898c9f5d6-dzbl9   1/1     Running   2 (4m37s ago)   4m40s
pod/catalog-mysql-0            1/1     Running   0               4m40s

NAME                    TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE
service/catalog         ClusterIP   172.20.127.102   <none>        80/TCP     4m40s
service/catalog-mysql   ClusterIP   172.20.197.206   <none>        3306/TCP   4m40s

NAME                      READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/catalog   1/1     1            1           4m41s

NAME                                 DESIRED   CURRENT   READY   AGE
replicaset.apps/catalog-6898c9f5d6   1         1         1       4m41s

NAME                             READY   AGE
statefulset.apps/catalog-mysql   1/1     4m41s
```

You've succefully deployed an application using Argo CD with the `GitOps` model. 
