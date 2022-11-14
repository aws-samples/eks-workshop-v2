---
title: "Baseline PSS Profile"
sidebar_position: 20
---

In the section, we will look at the following scenario.

#### All PSA Modes Enabled for Baseline PSS Profile at Namespace Level

In this scenario, we will enable all PSA modes (i.e. enforce, audit and warn) for Baseline PSS profile for a namespace.
## Review existing Pod security configuration

Let's ensure that there are no PSA labels added to the `assets` namespace, by default.

You can check current labels for namespace using below command.

```bash  timeout=60 hook=baseline-namespace-no-labels
$ kubectl describe ns assets
Name:         assets
Labels:       app.kubernetes.io/created-by=eks-workshop
              kubernetes.io/metadata.name=assets
Annotations:  <none>
Status:       Active

No resource quota.

No LimitRange resource.
```
As you see, the `assets` namespace does not have any PSA labels attached.

Let us also check for currently running Deployment and Pod in the `assets` namespace.

```bash  test=false
$ kubectl -n assets get deploy
NAME     READY   UP-TO-DATE   AVAILABLE   AGE
assets   1/1     1            1           5m24s

$ kubectl -n assets  get pod
NAME                     READY   STATUS    RESTARTS   AGE
assets-ddb8f87dc-8z6l9   1/1     Running   0          5m24s
```

Let us also review the security configuration applied currently for the above Pod in `assets` namespace.

```bash test=false
$ kubectl -n assets get deploy -oyaml 
...
    spec:
      serviceAccountName: assets
      securityContext:
        {}
      containers:
        - name: assets
          envFrom:
            - configMapRef:
                name: assets
          securityContext:
            capabilities:
              drop:
              - ALL
            readOnlyRootFilesystem: false
          image: "watchn/watchn-assets:build.1615751790"
          imagePullPolicy: IfNotPresent
          ports:
            - name: http
              containerPort: 8080
              protocol: TCP
...

```

In the above Pod security configuration, the `securityContext` is nil at the Pod level. At the container level, the `securityContext` is configured to drop all the linux capabilities and `readOnlyRootFilesystem` is set to false.

## Add PSA labels for Baseline PSS profile to the namespace

Let us add labels to the `assets` namespace to enable all PSA modes for the Baseline PSS profile.

```kustomization
security/pss-psa/baseline/namespace/namespace.yaml
Namespace/assets
```
Run Kustomize to apply this change to add labels to the `assets` namespace.

```bash timeout=60 hook=baseline-namespace
$ kubectl apply -k /workspace/modules/security/pss-psa/baseline/namespace
namespace/assets configured
serviceaccount/assets unchanged
configmap/assets unchanged
service/assets unchanged
Deployment.apps/assets unchanged
```
Run below command to see if the PSA labels are added to the `assets` namespace

```bash  test=false
$ kubectl describe ns assets
Name:         assets
Labels:       app.kubernetes.io/created-by=eks-workshop
              kubernetes.io/metadata.name=assets
              Pod-security.kubernetes.io/audit=baseline
              Pod-security.kubernetes.io/enforce=baseline
              Pod-security.kubernetes.io/warn=baseline
Annotations:  <none>
Status:       Active

No resource quota.

No LimitRange resource.
```

Let us delete the Deployment and re-create it again without any changes to see if existing Pod security configuration confirms to the Baseline PSS profile, which we just configured for the `assets` namespace.

```bash
$ kubectl -n assets delete -f /workspace/manifests/assets/deployment.yaml
Deployment.apps "assets" deleted
```
Run below command to re-create the Deployment

```bash timeout=60 hook=baseline-deploy-no-changes
$ kubectl -n assets apply -f /workspace/manifests/assets/deployment.yaml
Deployment.apps "assets" created
```
Let us check if Deployment and Pod objects are created or not.

```bash  test=false
$ kubectl -n assets get deploy
NAME     READY   UP-TO-DATE   AVAILABLE   AGE
assets   1/1     1            1           3m36s

$ kubectl -n assets get pod   
NAME                     READY   STATUS    RESTARTS   AGE
assets-ddb8f87dc-rmv9n   1/1     Running   0          3m
```

As shown in above output, PSA allowed both Deployment and Pod objects creation with existing security configuration without any changes, under the Baseline PSS profile configured for the `assets` namespace.

## Add additional security permissions to the Pod

In the section, let us add some additional security permissions to the existing Pod configuration and re-create the Deployment. The idea here is to check how PSA behaves to these changes as per the Baseline PSS profile configured for the `assets` namespace

```kustomization
security/pss-psa/baseline/baseline/deployment.yaml
Deployment/assets
```
Before applying the above changes, let us first delete the Deployment and re-create it with above changes.

```bash timeout=60
$ kubectl -n assets delete deploy assets
Deployment.apps "assets" deleted
```

Run Kustomize to apply these changes, which we re-create the Deployment.

```bash timeout=60 hook=baseline-deploy-with-changes
$ kubectl apply -k /workspace/modules/security/pss-psa/baseline/baseline/
namespace/assets unchanged
serviceaccount/assets unchanged
configmap/assets unchanged
service/assets unchanged
Warning: would violate PodSecurity "baseline:latest": host namespaces (hostNetwork=true, hostPID=true, hostIPC=true), hostPort (container "assets" uses hostPort 8080), privileged (container "assets" must not set securityContext.privileged=true)
Deployment.apps/assets created
```
Notice the Warning message in the above output. This message comes because of the following PSA mode applied to Baseline PSS profile for the `assets` namespace.
Note that the above security permissions are not the comprehensive list of controls allowed under Baseline PSS profile. For detailed security controls allowed/disallowed under each PSS profile, refer to the [documentation](https://kubernetes.io/docs/concepts/security/pod-security-standards/#baseline)

```yaml
Pod-security.kubernetes.io/warn=baseline
```
Let us check if the Pod is created with above additional security permissions in the `assets` namespace.

```bash  test=false
$ kubectl -n assets get pod                                                                    
No resources found in assets namespace.
```
The above output indicates that PSA did not allow creation of Pods in the `assets` namespace, because the Pod security configuration violates Baseline PSS profile, as shown in the above Warning message.

This behaviour is because of the following PSA enforce mode applied to Baseline PSS profile for the `assets` namespace.

```yaml
Pod-security.kubernetes.io/enforce=baseline
```

What about the Deployment object then? Run below command to check if Deployment is created or not in the `assets` namespace.

```bash  test=false
$ kubectl -n assets get deploy                                                                 
NAME     READY   UP-TO-DATE   AVAILABLE   AGE
assets   0/1     0            0           13s
```
The above output indicates that Deployment is created but there are no Pods created.

## User experience (UX)

When used independently, the PSA modes have different responses that result in different user experiences. The enforce mode prevents Pods from being created if the respective Pod specs violate the configured PSS profile. However, in this mode, non-Pod Kubernetes objects that create Pods, such as Deployments, won’t be prevented from being applied to the cluster, even if the Pod spec therein violates the applied PSS profile. In this case, the Deployment is applied while the Pods are prevented from being applied.

In some scenarios, this is a difficult user experience, as there is no immediate indication that the successfully applied Deployment object reflects failed Pod creation. The offending Pod specs won’t create Pods. Inspecting the Deployment resource with kubectl get deploy <Deployment_NAME> -oyaml will expose the message from the failed Pod(s) .status.co.nditions element, as was seen in our testing above

In both the audit and warn PSA modes, the Pod restrictions don’t prevent violating Pods from being created and started. However, in these modes audit annotations on API server audit log events and warnings to API server clients (e.g., kubectl) are triggered, respectively. This occurs when Pods, as well as objects that create Pods, contain Pod specs with PSS violations. 

Run the below command to inspect the Deployment resource to find the status condition.

```bash  test=false
$ kubectl -n assets get deploy assets -oyaml
status:
  conditions:
  - lastTransitionTime: "2022-10-20T09:39:15Z"
    lastUpdateTime: "2022-10-20T09:39:15Z"
    message: Deployment does not have minimum availability.
    reason: MinimumReplicasUnavailable
    status: "False"
    type: Available
  - lastTransitionTime: "2022-10-20T09:39:15Z"
    lastUpdateTime: "2022-10-20T09:39:15Z"
    message: 'Pods "assets-5889bdfd49-jrm69" is forbidden: violates PodSecurity "baseline:latest":
      host namespaces (hostNetwork=true, hostPID=true, hostIPC=true), hostPort (container
      "assets" uses hostPort 8080), privileged (container "assets" must not set securityContext.privileged=true)'
    reason: FailedCreate
    status: "True"
```
While the Deployment was created, the Pod was not. It’s clear that a best practice would be to use warn and audit modes at all times, for a better user experience.

## Cleanup

Let us revert the changes by first deleting the deployment. 

```bash
$ kubectl -n assets delete deploy assets
deployment.apps "assets" deleted
```
Then re-deploy it from the original manifest.

```bash
$ kubectl apply -k /workspace/manifests/assets
namespace/assets configured
serviceaccount/assets unchanged
configmap/assets unchanged
service/assets unchanged
deployment.apps/assets created
```
