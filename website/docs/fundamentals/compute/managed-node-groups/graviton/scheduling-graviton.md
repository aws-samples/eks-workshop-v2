---
title: Run pods on Graviton
sidebar_position: 20
---

Now that we have tainted our Graviton node group, we'll need to configure our application to take advantage of this change. To do so, let's configure our application to deploy the `ui` microservice only on nodes that are part of our Graviton-based managed node group.

Before making any changes, let's check the current configuration for the UI pods. Keep in mind that these pods are being controlled by an associated deployment named `ui`.

```bash
$ kubectl describe pod --namespace ui --selector app.kubernetes.io/name=ui
Name:             ui-7bdbf967f9-qzh7f
Namespace:        ui
Priority:         0
Service Account:  ui
Node:             ip-10-42-11-43.us-west-2.compute.internal/10.42.11.43
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

As anticipated, the application is running successfully on a non-tainted node. The associated pod is in a `Running` status and we can confirm that no custom tolerations have been configured. Note that Kubernetes automatically adds tolerations for `node.kubernetes.io/not-ready` and `node.kubernetes.io/unreachable` with `tolerationSeconds=300`, unless you or a controller set those tolerations explicitly. These automatically-added tolerations mean that Pods remain bound to Nodes for 5 minutes after one of these problems is detected.

Let's update our `ui` deployment to bind its pods to our tainted managed node group. We have pre-configured our tainted managed node group with a label of `tainted=yes` that we can use with a `nodeSelector`. The following `Kustomize` patch describes the changes needed to our deployment configuration in order to enable this setup:

```kustomization
modules/fundamentals/mng/graviton/nodeselector-wo-toleration/deployment.yaml
Deployment/ui
```
In the above manifest, the `nodeSelector` specifies that pods should only be scheduled on nodes with the label `kubernetes.io/arch: arm64`. This `nodeSelector` effectively restricts the UI pods to run only on ARM64 architecture nodes (Graviton nodes).

To apply the Kustomize changes run the following command:

```bash
$ kubectl apply -k ~/environment/eks-workshop/modules/fundamentals/mng/graviton/nodeselector-wo-toleration/
namespace/ui unchanged
serviceaccount/ui unchanged
configmap/ui unchanged
service/ui unchanged
deployment.apps/ui configured
```

With our recently made changes, let's check the rollout status of our UI deployment:

```bash
$ kubectl --namespace ui rollout status --watch=false deployment/ui
Waiting for deployment "ui" rollout to finish: 1 old replicas are pending termination...
```

Given the default `RollingUpdate` strategy for our `ui` deployment, the K8s deployment will wait for the newly created pod to be in `Ready` state before terminating the old one. The deployment rollout seems stuck so let's investigate further:

```bash hook=pending-pod
$ kubectl get pod --namespace ui -l app.kubernetes.io/name=ui
NAME                  READY   STATUS    RESTARTS   AGE
ui-659df48c56-z496x   0/1     Pending   0          16s
ui-795bd46545-mrglh   1/1     Running   0          8m
```

Investigating the individual pods under the `ui` namespace we can observe that one pod is in `Pending` state. Diving deeper into the `Pending` Pod's details provides some information on the experienced issue.

```bash
$ podname=$(kubectl get pod --namespace ui --field-selector=status.phase=Pending -o json | \
                jq -r '.items[0].metadata.name') && \
                kubectl describe pod $podname -n ui
Name:           ui-659df48c56-z496x
Namespace:      ui
[...]
Node-Selectors:              kubernetes.io/arch=arm64
Tolerations:                 node.kubernetes.io/not-ready:NoExecute op=Exists for 300s
                             node.kubernetes.io/unreachable:NoExecute op=Exists for 300s
Events:
  Type     Reason            Age   From               Message
  ----     ------            ----  ----               -------
  Warning  FailedScheduling  19s   default-scheduler  0/4 nodes are available: 1 node(s) had untolerated taint {frontend: true}, 3 node(s) didn't match Pod's node affinity/selector. preemption: 0/4 nodes are available: 4 Preemption is not helpful for scheduling.
```

Our changes are reflected in the new configuration of the `Pending` pod. We can see that we have pinned the pod to any node with the `tainted=yes` label but this introduced a new problem as our pod cannot be scheduled (`PodScheduled False`). A more useful explanation can be found under the `events`:

```text
0/4 nodes are available: 1 node(s) had untolerated taint {frontend: true}, 3 node(s) didn't match Pod's node affinity/selector. preemption: 0/4 nodes are available: 4 Preemption is not helpful for scheduling.
```

To fix this, we need to add a toleration. Let's ensure our deployment and associated pods are able to tolerate the `frontend: true` taint. We can use the below `kustomize` patch to make the necessary changes:

```kustomization
modules/fundamentals/mng/graviton/nodeselector-w-toleration/deployment.yaml
Deployment/ui
```
This YAML builds upon the previous configuration by adding a toleration. The `tolerations` section allows the pod to be scheduled on nodes with the `frontend` taint as explained below:
- `key: "frontend"` specifies the taint key to tolerate.
- `operator: "Exists"` means the pod will tolerate the taint regardless of its value.
- `effect: "NoExecute"` matches the taint effect, allowing the pod to run on nodes with this taint.

The nodeSelector remains the same, ensuring pods run only on ARM64 architecture nodes. To apply the Kustomize changes run the following command:

```bash
$ kubectl apply -k ~/environment/eks-workshop/modules/fundamentals/mng/graviton/nodeselector-w-toleration/
namespace/ui unchanged
serviceaccount/ui unchanged
configmap/ui unchanged
service/ui unchanged
deployment.apps/ui configured
$ kubectl --namespace ui rollout status deployment/ui --timeout=120s
```

Checking the UI pod, we can see that the configuration now includes the specified toleration (`frontend=true:NoExecute`) and it is successfully scheduled on the node with corresponding taint. The following commands can be used for validation:

```bash
$ kubectl get pod --namespace ui -l app.kubernetes.io/name=ui
NAME                  READY   STATUS    RESTARTS   AGE
ui-6c5c9f6b5f-7jxp8   1/1     Running   0          29s
```

```bash
$ kubectl describe pod --namespace ui -l app.kubernetes.io/name=ui
Name:         ui-6c5c9f6b5f-7jxp8
Namespace:    ui
Priority:     0
Node:         ip-10-42-10-138.us-west-2.compute.internal/10.42.10.138
Start Time:   Fri, 11 Nov 2022 13:00:36 +0000
Labels:       app.kubernetes.io/component=service
              app.kubernetes.io/created-by=eks-workshop
              app.kubernetes.io/instance=ui
              app.kubernetes.io/name=ui
              pod-template-hash=6c5c9f6b5f
Annotations:  kubernetes.io/psp: eks.privileged
              prometheus.io/path: /actuator/prometheus
              prometheus.io/port: 8080
              prometheus.io/scrape: true
Status:       Running
IP:           10.42.10.225
IPs:
  IP:           10.42.10.225
Controlled By:  ReplicaSet/ui-6c5c9f6b5f
Containers:
  [...]
Conditions:
  Type              Status
  Initialized       True
  Ready             True
  ContainersReady   True
  PodScheduled      True
[...]
QoS Class:                   Burstable
Node-Selectors:              kubernetes.io/arch=arm64
Tolerations:                 frontend:NoExecute op=Exists
                             node.kubernetes.io/not-ready:NoExecute op=Exists for 300s
                             node.kubernetes.io/unreachable:NoExecute op=Exists for 300s
[...]
```

```bash
$ kubectl describe node --selector kubernetes.io/arch=arm64
Name:               ip-10-42-10-138.us-west-2.compute.internal
Roles:              <none>
Labels:             beta.kubernetes.io/instance-type=t4g.medium
                    beta.kubernetes.io/os=linux
                    eks.amazonaws.com/capacityType=ON_DEMAND
                    eks.amazonaws.com/nodegroup=graviton
                    eks.amazonaws.com/nodegroup-image=ami-03e8f91597dcf297b
                    kubernetes.io/arch=arm64
                    kubernetes.io/hostname=ip-10-42-10-138.us-west-2.compute.internal
                    kubernetes.io/os=linux
                    node.kubernetes.io/instance-type=t4g.medium
[...]
Taints:             frontend=true:NoExecute
Unschedulable:      false
[...]
```

As you can see, the `ui` pod is now running on the Graviton-based node group. In addition, you can see the Taints on the `kubectl describe node` command, and the matching Tolerations on the `kubectl describe pod` command.

You've successfully scheduled the `ui` application, which can run on both Intel and ARM-based processors, to run on the new Graviton-based managed node group we created in the previous step. Taints and tolerations are a powerful tool that can be used to configure how pods get scheduled onto nodes, whether it's for Graviton/GPU-enhanced nodes, or for multi-tenant Kubernetes clusters.
