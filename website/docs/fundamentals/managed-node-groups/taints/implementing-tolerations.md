---
title: Configure our application with tolerations
sidebar_position: 20
---

Before making any changes, let's check the current configuration for the UI pods. Keep in mind that these pods are being controlled by an associated deployment.

```bash
$ kubectl describe pod --namespace ui -l app.kubernetes.io/name=ui
Name:             ui-7bdbf967f9-qzh7f
Namespace:        ui
Priority:         0
Service Account:  ui
Node:             ip-10-42-11-43.eu-west-1.compute.internal/10.42.11.43
Start Time:       Wed, 09 Nov 2022 16:40:32 +0000
Labels:           app.kubernetes.io/component=service
                  app.kubernetes.io/created-by=eks-workshop
                  app.kubernetes.io/instance=ui
                  app.kubernetes.io/name=ui
                  pod-template-hash=7bdbf967f9
Status:           Running
[....]
Controlled By:  ReplicaSet/ui-7bdbf967f9
Containers:
[...]
Node-Selectors:              <none>
Tolerations:                 node.kubernetes.io/not-ready:NoExecute op=Exists for 300s
                             node.kubernetes.io/unreachable:NoExecute op=Exists for 300s
```
Although there are no tolerations configured in our spec files, a few default ones have been automatically assigned. It's important to recognise that although we have configured one of the existing node groups with a taint (`frontend=true:NoExecute`) the pod is still running as expected. This is because the UI deployment and associated pod is currently scheduled on nodes that are part of a different managed node group. 

The next couple of commands will help us update the `UI` deployment with a corresponding toleration to allow it to be scheduled on our tainted nodes. For our workshop purposes we want to ensure that the UI pods are scheduled on our tainted managed node group. As previosly stated, configuring tolerations is not enough to ensure pods can **only** be scheduled on our tainted nodes. As such, we will need also need to make use of `NodeSelector` to specifically choose our tainted node. The following `Kustomize` patch describes the changes we need to make to our deployment to enable this configuration: 

```kustomization
fundamentals/mng/taints/deployment.yaml
Deployment/ui
```
To apply the Kustomize changes run the following command: 

```bash
$ kubectl apply -k /workspace/modules/fundamentals/mng/taints/
namespace/ui unchanged
serviceaccount/ui unchanged
configmap/ui unchanged
service/ui unchanged
deployment.apps/ui configured
```
Checking the UI pod, we can see that the configuration now includes the specified toleration (`frontend=true:NoExecute`) and it's scheduled on the node with corresponding taint. 

```bash
$ kubectl describe pod --namespace ui -l app.kubernetes.io/name=ui
Name:             ui-6c5c9f6b5f-pfltt
Namespace:        ui
Priority:         0
Service Account:  ui
Node:             ip-10-42-12-233.eu-west-1.compute.internal/10.42.12.233
Start Time:       Wed, 09 Nov 2022 17:41:42 +0000
Labels:           app.kubernetes.io/component=service
                  app.kubernetes.io/created-by=eks-workshop
                  app.kubernetes.io/instance=ui
                  app.kubernetes.io/name=ui
                  pod-template-hash=6c5c9f6b5f
Controlled By:  ReplicaSet/ui-6c5c9f6b5f
Containers:
[...]
Node-Selectors:              tainted=yes
Tolerations:                 frontend:NoExecute op=Exists
                             node.kubernetes.io/not-ready:NoExecute op=Exists for 300s
                             node.kubernetes.io/unreachable:NoExecute op=Exists for 300s
[...]
$ kubectl describe node -l tainted=yes
Name:               ip-10-42-12-233.eu-west-1.compute.internal
Roles:              <none>
Labels:             beta.kubernetes.io/arch=amd64
                    [...]
                    kubernetes.io/arch=amd64
                    kubernetes.io/hostname=ip-10-42-12-233.eu-west-1.compute.internal
                    kubernetes.io/os=linux
                    node.kubernetes.io/instance-type=m5.large
                    topology.ebs.csi.aws.com/zone=eu-west-1c
                    topology.kubernetes.io/region=eu-west-1
                    topology.kubernetes.io/zone=eu-west-1c
                    workshop-default=no
                    tainted=yes    
[...]
```
