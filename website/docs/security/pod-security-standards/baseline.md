---
title: "Baseline PSS Profile"
sidebar_position: 20
---

What if we want to restrict the permissions that a Pod can request? For example the `privileged` permissions we provided to the assets Pod in the previous section can be dangerous, allowing an attacker access to the hosts resources outside of the container. 

The Baseline PSS is a minimally restrictive policy which prevents known privilege escalations. Let's add labels to the `assets` Namespace to enable it:

```kustomization
security/pss-psa/baseline-namespace/namespace.yaml
Namespace/assets
```

Run Kustomize to apply this change to add labels to the `assets` namespace:

```bash
$ kubectl apply -k /workspace/modules/security/pss-psa/baseline-namespace
Warning: existing pods in namespace "assets" violate the new PodSecurity enforce level "baseline:latest"
Warning: assets-64c49f848b-gmrtt: privileged
namespace/assets configured
serviceaccount/assets unchanged
configmap/assets unchanged
service/assets unchanged
deployment.apps/assets unchanged
```

You can see above that we've already been given a warning that Pods in the `assets` Deployment violate the Baseline PSS, which is provided by the Namespace label `pod-security.kubernetes.io/warn`. Now recycle the Pods in the `assets` Deployment:

```bash
$ kubectl -n assets delete pod --all
```

Let us check if the Pods are running:

```bash
$ kubectl -n assets get pod   
No resources found in assets namespace.
```

As you can see no Pods are running, caused by the Namespace label `pod-security.kubernetes.io/enforce`, though we don't immediately know why. When used independently the PSA modes have different responses that result in different user experiences. The enforce mode prevents Pods from being created if the respective Pod specs violate the configured PSS profile. However in this mode non-Pod Kubernetes objects that create Pods, such as Deployments, won’t be prevented from being applied to the cluster, even if the Pod spec therein violates the applied PSS profile. In this case the Deployment is applied while the Pods are prevented from being applied.

Run the below command to inspect the Deployment resource to find the status condition:

```bash
$ kubectl get deployment -n assets assets -o yaml | yq '.status'
- lastTransitionTime: "2022-11-24T04:49:56Z"
  lastUpdateTime: "2022-11-24T05:10:41Z"
  message: ReplicaSet "assets-7445d46757" has successfully progressed.
  reason: NewReplicaSetAvailable
  status: "True"
  type: Progressing
- lastTransitionTime: "2022-11-24T05:10:49Z"
  lastUpdateTime: "2022-11-24T05:10:49Z"
  message: 'pods "assets-67d5fc995b-8r9t2" is forbidden: violates PodSecurity "baseline:latest": privileged (container "assets" must not set securityContext.privileged=true)'
  reason: FailedCreate
  status: "True"
  type: ReplicaFailure
- lastTransitionTime: "2022-11-24T05:10:56Z"
  lastUpdateTime: "2022-11-24T05:10:56Z"
  message: Deployment does not have minimum availability.
  reason: MinimumReplicasUnavailable
  status: "False"
  type: Available
```

In some scenarios there is no immediate indication that the successfully applied Deployment object reflects failed Pod creation. The offending Pod specifications won’t create Pods. Inspecting the Deployment resource with `kubectl get deploy -o yaml ...` will expose the message from the failed Pod(s) `.status.conditions` element as was seen in our testing above.

In both the audit and warn PSA modes, the Pod restrictions don’t prevent violating Pods from being created and started. However in these modes audit annotations on API server audit log events and warnings to API server clients (e.g., kubectl) are triggered, respectively. This occurs when Pods, as well as objects that create Pods, contain Pod specs with PSS violations.

Now, let's fix the `assets` Deployment so it will run by removing the `privileged` flag:

```bash
$ kubectl apply -k /workspace/modules/security/pss-psa/baseline-workload
namespace/assets unchanged
serviceaccount/assets unchanged
configmap/assets unchanged
service/assets unchanged
deployment.apps/assets configured
```

This time we didn't receive a warning so check if the Pods are running, and we can validate it's not running with the `root` user anymore:

```bash
$ kubectl -n assets get pod   
NAME                      READY   STATUS    RESTARTS   AGE
assets-864479dc44-d9p79   1/1     Running   0          15s

$ kubectl -n assets exec $(kubectl -n assets get pods -o name) -- whoami
nginx
```

Since we remediated the Pod running in `privileged` mode it is now permitted to run under the Baseline profile.
