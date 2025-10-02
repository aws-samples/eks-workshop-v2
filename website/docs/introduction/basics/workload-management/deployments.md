---
title: Deployments
sidebar_position: 31
---

# Deployments

**Deployments** are the most common workload controller for running stateless applications. They create and manage multiple identical pods, handling scaling, updates, and recovery automatically.

Key benefits:
- **Multiple identical pods** - Run several copies of your application
- **Automatic scaling** - Easily increase or decrease pod count
- **Self-healing** - Replace failed pods automatically
- **Rolling updates** - Update without downtime
- **Easy rollbacks** - Revert to previous versions

### Deploying an Application

Let's deploy the retail store UI using a deployment:

::yaml{file="manifests/base-application/ui/deployment.yaml" paths="kind,metadata.name,spec.replicas,spec.selector,spec.template" title="deployment.yaml"}

1. `kind: Deployment`: Creates a deployment controller
2. `metadata.name`: Name of the deployment (ui)
3. `spec.replicas`: Number of pods to run (1 in this case)
4. `spec.selector`: How deployment finds its pods (by labels)
5. `spec.template`: Pod template defining what each pod looks like

Deploy the application:
```bash
$ kubectl apply -f ~/environment/eks-workshop/manifests/base-application/ui/
```

### Inspecting Your Deployment

Check deployment status:
```bash
$ kubectl get deployment -n ui
```

You'll see output like:
```
NAME   READY   UP-TO-DATE   AVAILABLE   AGE
ui     1/1     1            1           30s
```

View the pods created by the deployment:
```bash
$ kubectl get pods -n ui
```

Notice the pod name includes the deployment name plus a random suffix:
```
NAME                  READY   STATUS    RESTARTS   AGE
ui-6d5bb7b9c8-xyz12   1/1     Running   0          30s
```

Get detailed deployment information:
```bash
$ kubectl describe deployment -n ui ui
```

### Scaling Your Deployment

Scale up to 3 replicas:
```bash
$ kubectl scale deployment -n ui ui --replicas=3
```

Verify the scaling:
```bash
$ kubectl get pods -n ui
```

You'll now see 3 pods running:
```
NAME                  READY   STATUS    RESTARTS   AGE
ui-6d5bb7b9c8-abc12   1/1     Running   0          2m
ui-6d5bb7b9c8-def34   1/1     Running   0          10s
ui-6d5bb7b9c8-ghi56   1/1     Running   0          10s
```

Scale back down:
```bash
$ kubectl scale deployment -n ui ui --replicas=1
```

### Key Points to Remember

* Deployments manage multiple identical pods automatically
* Use deployments instead of creating pods directly in production
* Scaling is as simple as changing the replica count
* Pod names include the deployment name plus random suffixes
* Deployments are perfect for stateless applications like web apps and APIs

### Next Steps

Now that you understand deployments, explore other workload controllers:
- **[StatefulSets](./statefulsets)** - For stateful applications like databases
- **[DaemonSets](./daemonsets)** - For node-level services
- **[Jobs](./jobs)** - For batch processing and scheduled tasks

Or learn about **[Services](../services)** - how to provide stable network access to your deployments.