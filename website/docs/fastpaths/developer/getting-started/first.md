---
title: Deploying our first component
sidebar_position: 40
---

The sample application is composed of a set of Kubernetes manifests organized in a way that can be easily applied with Kustomize. Kustomize is an open-source tool also provided as a native feature of the `kubectl` CLI. This workshop uses Kustomize to apply changes to Kubernetes manifests, making it easier to understand changes to manifest files without needing to manually edit YAML. As we work through the various modules of this workshop, we'll incrementally apply overlays and patches with Kustomize.

The easiest way to browse the YAML manifests for the sample application and the modules in this workshop is using the file browser in the IDE:

![IDE files](./assets/ide-initial.webp)

Expanding the `eks-workshop` and then `base-application` items will allow you to browse the manifests that make up the initial state of the sample application:

![IDE files base](./assets/ide-base.webp)

The structure consists of a directory for each application component that was outlined in the **Sample application** section.

The `modules` directory contains sets of manifests that we will apply to the cluster throughout the subsequent lab exercises:

![IDE files modules](./assets/ide-modules.webp)

Before we do anything lets inspect the current Namespaces in our EKS cluster:

```bash
$ kubectl get namespaces
NAME                            STATUS   AGE
default                         Active   1h
kube-node-lease                 Active   1h
kube-public                     Active   1h
kube-system                     Active   1h
```

All of the entries listed are Namespaces for system components that were pre-installed for us. We'll ignore most of these by using [Kubernetes labels](https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/) to filter the Namespaces down to only those we've created:

```bash
$ kubectl get namespaces -l app.kubernetes.io/created-by=eks-workshop
ui         Active   21h
```

The first thing we'll do is deploy the catalog component by itself. The manifests for this component can be found in `~/environment/eks-workshop/base-application/catalog`.

```bash
$ ls ~/environment/eks-workshop/base-application/catalog
configMap.yaml
deployment.yaml
kustomization.yaml
namespace.yaml
secrets.yaml
service-mysql.yaml
service.yaml
serviceAccount.yaml
statefulset-mysql.yaml
```

These manifests include the Deployment for the catalog API which expresses the desired state of the catalog API component:

::yaml{file="manifests/base-application/catalog/deployment.yaml" paths="spec.replicas,spec.template.metadata.labels,spec.template.spec.containers.0.image,spec.template.spec.containers.0.ports,spec.template.spec.containers.0.livenessProbe,spec.template.spec.containers.0.resources"}

1. Run a single replica
2. Apply labels to the Pods so other resources can refer to them
3. Use the `public.ecr.aws/aws-containers/retail-store-sample-catalog` container image
4. Expose the container on port 8080 named `http`
5. Run [probes/healthchecks](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/) against the `/health` path
6. [Requests](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/) a specific amount of CPU and memory so the Kubernetes scheduler can place it on a node with enough available resources

The manifests also include the Service used by other components to access the catalog API:

::yaml{file="manifests/base-application/catalog/service.yaml" paths="spec.ports,spec.selector"}

1. Exposes itself on port 80 and targets the `http` port exposed by the Deployment, which translates to port 8080
2. Selects catalog Pods using labels that match what we expressed in the Deployment above

Let's create the catalog component:

```bash
$ kubectl apply -k ~/environment/eks-workshop/base-application/catalog
namespace/catalog created
serviceaccount/catalog created
configmap/catalog created
secret/catalog-db created
service/catalog created
service/catalog-mysql created
deployment.apps/catalog created
statefulset.apps/catalog-mysql created
```

:::info EKS Auto Mode Compute Provisioning
When you deploy workloads to Amazon EKS Auto Mode, the cluster automatically provisions EC2 instances to run your Pods. Let's observe this process in real-time.
:::



```bash
$ kubectl get pod -n catalog
NAME                      READY   STATUS    RESTARTS      AGE
catalog-5fdcc8c65-jkg9f   1/1     Running   2 (87s ago)   2m6s
catalog-mysql-0           1/1     Running   0             2m5s
```

<!-- Notice we have a Pod for our catalog API and another for the MySQL database. If the `catalog` Pod is showing a status of `CrashLoopBackOff`, it needs to be able to connect to the `catalog-mysql` Pod before it will start. Kubernetes will keep restarting it until this is the case. In that case, we can use [kubectl wait](https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#wait) to monitor specific Pods until they are in a Ready state: -->

If the pods aren't ready yet, we can use [kubectl wait](https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#wait) for them to become ready.

```bash
$ kubectl wait --for=condition=Ready pods --all -n catalog --timeout=180s
```

Now that the Pods are running we can [check their logs](https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#logs), for example the catalog API:

:::tip
You can ["follow" the kubectl logs output](https://kubernetes.io/docs/reference/kubectl/cheatsheet/) by using the '-f' option with the command. (Use CTRL-C to stop following the output)
:::

```bash
$ kubectl logs -n catalog deployment/catalog
```

Kubernetes also allows us to easily scale the number of catalog Pods horizontally:

```bash
$ kubectl scale -n catalog --replicas 3 deployment/catalog
deployment.apps/catalog scaled
$ kubectl wait --for=condition=Ready pods --all -n catalog --timeout=180s
```

:::info Auto Mode Automatic Scaling
EKS Auto Mode automatically scales compute capacity to match your workload demands. If you scale to more replicas than the current node can handle, Auto Mode will provision additional nodes automatically. The cluster continuously optimizes node placement and capacity based on your Pod resource requirements.
:::

The manifests we applied also create a Service for each of our application and MySQL Pods that can be used by other components in the cluster to connect:

```bash
$ kubectl get svc -n catalog
NAME            TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE
catalog         ClusterIP   172.20.83.84     <none>        80/TCP     2m48s
catalog-mysql   ClusterIP   172.20.181.252   <none>        3306/TCP   2m48s
```

These Services are internal to the cluster, so we cannot access them from the Internet or even the VPC. However, we can use [exec](https://kubernetes.io/docs/tasks/debug/debug-application/get-shell-running-container/) to access an existing Pod in the EKS cluster to check the catalog API is working:

```bash
$ kubectl -n catalog exec -i \
  deployment/catalog -- curl catalog.catalog.svc/catalog/products | jq .
```

You should receive back a JSON payload with product information. Congratulations, you've just deployed your first microservice to Kubernetes with EKS!
