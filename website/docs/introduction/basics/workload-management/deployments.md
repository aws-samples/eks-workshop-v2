---
title: Deployments
sidebar_position: 31
sidebar_custom_props: { "module": true }
---

# Deployments

::required-time

:::tip Before you start
Prepare your environment for this section:

```bash timeout=300 wait=10
$ prepare-environment introduction/basics/deployments
```

:::

**Deployments** are the most common workload controller for running stateless applications. They make sure your application always runs the desired number of Pods - automatically handling creation, scaling, updates, and recovery.

Instead of managing Pods manually, Deployments let Kubernetes:
- **Run multiple identical Pods** for reliability and load distribution
- **Scale automatically** by adjusting replica counts
- **Recover failed Pods** without manual intervention
- **Perform rolling** updates without downtime
- **Rollback easily** to previous versions when needed

### Creating a Deployment

Let's deploy the retail store UI using a deployment:

::yaml{file="manifests/base-application/ui/deployment.yaml" paths="kind,metadata.name,spec.replicas,spec.selector,spec.template" title="deployment.yaml"}

1. `kind: Deployment`: Defines a Deployment controller
2. `metadata.name`: Name of the Deployment (ui)
3. `spec.replicas`: Desired number of pods (1 in this example)
4. `spec.selector`: Labels used to find managed Pods
5. `spec.template`: Pod template defining what each pod should looks like

The deployment ensures that the actual Pods always match this template. 

Apply the Deployments:
```bash
$ kubectl apply -k ~/environment/eks-workshop/base-application/ui
```

### Inspecting Deployment

Check deployment status:
```bash
$ kubectl get deployment -n ui
NAME   READY   UP-TO-DATE   AVAILABLE   AGE
ui     1/1     1            1           30s
```

List the Pods created by the Deployment:
```bash
$ kubectl get pods -n ui
NAME                  READY   STATUS    RESTARTS   AGE
ui-6d5bb7b9c8-xyz12   1/1     Running   0          30s
```

Get detailed information:
```bash
$ kubectl describe deployment -n ui ui
```

### Scaling Deployment

Scale up to 5 replicas:
```bash
$ kubectl scale deployment -n ui ui --replicas=5
$ kubectl get pods -n ui
NAME                  READY   STATUS    RESTARTS   AGE
ui-6d5bb7b9c8-abc12   1/1     Running   0          2m
ui-6d5bb7b9c8-def34   1/1     Running   0          12s
ui-6d5bb7b9c8-ghi56   1/1     Running   0          12s
ui-6d5bb7b9c8-arx97   1/1     Running   0          10s
ui-6d5bb7b9c8-uiv85   1/1     Running   0          10s
```

:::info
Kubernetes automatically spreads these Pods across available worker nodes for high availability.
:::

Scale back down to 3 replicas:
```bash
$ kubectl scale deployment -n ui ui --replicas=3
$ kubectl get pods -n ui
NAME                  READY   STATUS    RESTARTS   AGE
ui-6d5bb7b9c8-abc12   1/1     Running   0          2m
ui-6d5bb7b9c8-def34   1/1     Running   0          12s
ui-6d5bb7b9c8-ghi56   1/1     Running   0          12s
```

### Rolling Updates and Rollbacks
You can update a Deployment by changing the image version:
```bash
$ kubectl set image deployment/ui ui=public.ecr.aws/aws-containers/retail-store-sample-ui:v2 -n ui
$ kubectl get pods -n ui
NAME                  READY   STATUS         RESTARTS   AGE
ui-5989474687-5gcbt   1/1     Running        0          13m
ui-5989474687-dhk6q   1/1     Running        0          14s
ui-5989474687-dw8x8   1/1     Running        0          14s
ui-7c65b44b7c-znm9c   0/1     ErrImagePull   0          7s
```
> You'll see a new pod created but with status `ErrImagePull`.

Now let's rollback the change 
```bash
$ kubectl rollout undo deployment/ui -n ui
$ kubectl get pods -n ui
NAME                  READY   STATUS         RESTARTS   AGE
ui-5989474687-5gcbt   1/1     Running        0          13m
ui-5989474687-dhk6q   1/1     Running        0          14s
ui-5989474687-dw8x8   1/1     Running        0          14s
```

Rolling updates let you update your application gradually without downtime, while Kubernetes ensures new Pods match the desired state.
If something goes wrong — like an invalid image — you can rollback safely to the previous working version, keeping your application available and stable.

This demonstrates how Deployments simplify application updates, maintain availability, and reduce risk in production environments.

### Key Points to Remember

* Deployments manage multiple identical pods automatically
* Use deployments instead of creating pods directly in production
* Scaling is as simple as changing the replica count
* Pod names include the deployment name plus random suffixes
* Deployments are perfect for stateless applications like web apps and APIs
