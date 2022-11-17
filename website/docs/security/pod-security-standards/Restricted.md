---
title: "Restricted PSS Profile"
sidebar_position: 30
---

In the section, we will look at the following scenario.

#### All PSA Modes Enabled for Restricted PSS Profile at Namespace Level

In this scenario, we will enable all PSA modes (i.e. enforce, audit and warn) for Restricted PSS profile for a namespace.
## Review existing Pod security configuration

Let's ensure that there are no PSA labels added to the `assets` namespace, by default.

You can check current labels for namespace using below command.

```bash  timeout=60 hook=restricted-namespace-no-labels
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
assets   1/1     1            1           5m24sh

$ kubectl -n assets  get pod
NAME                     READY   STATUS    RESTARTS   AGE
assets-ddb8f87dc-8z6l9   1/1     Running   0          5m24s
```

Let us also review the security configuration applied currently for the above Pod in `assets` namespace.

```bash  test=false
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

## Add PSA labels for Restricted PSS profile to the namespace

Let us add labels to the `assets` namespace to enable all PSA modes for the Restricted PSS profile.

```kustomization
security/pss-psa/restricted/namespace/namespace.yaml
Namespace/assets
```
Run Kustomize to apply this change to add labels to the `assets` namespace.

```bash  timeout=180 hook=restricted-namespace
$ kubectl apply -k /workspace/modules/security/pss-psa/restricted/namespace
Warning: existing pods in namespace "assets" violate the new PodSecurity enforce level "restricted:latest"
Warning: assets-d59d88b99-flkgp: hostPort, allowPrivilegeEscalation != false, runAsNonRoot != true, seccompProfile
namespace/assets configured
serviceaccount/assets unchanged
configmap/assets unchanged
service/assets unchanged
deployment.apps/assets unchanged
```
Did you see Warning messages in the above output? Looks like there are some security violations with current Pod security configuration. We will look into them shortly.

Run below command to see if the PSA labels are added to `assets` namespace
 
```bash test=false
$ kubectl describe ns assets
Name:         assets
Labels:       app.kubernetes.io/created-by=eks-workshop
              kubernetes.io/metadata.name=assets
              pod-security.kubernetes.io/audit=restricted
              pod-security.kubernetes.io/enforce=restricted
              pod-security.kubernetes.io/warn=restricted
Annotations:  <none>
Status:       Active

No resource quota.

No LimitRange resource.
```

Let us delete the Deployment and re-create it again without any changes to see if existing Pod security configuration confirms to the Restricted PSS profile, which we just configured for the `assets` namespace.

```bash
$ kubectl -n assets delete -f /workspace/manifests/assets/deployment.yaml
Deployment.apps "assets" deleted
```
Run below command to re-create the Deployment.

```bash timeout=180 hook=restricted-deploy-no-changes
$ kubectl -n assets apply -f /workspace/manifests/assets/deployment.yaml
Warning: would violate PodSecurity "restricted:latest": allowPrivilegeEscalation != false (container "assets" must set securityContext.allowPrivilegeEscalation=false), runAsNonRoot != true (pod or container "assets" must set securityContext.runAsNonRoot=true), seccompProfile (pod or container "assets" must set securityContext.seccompProfile.type to "RuntimeDefault" or "Localhost")
deployment.apps/assets created
```
As shown in the above output, PSA did not allow pod creation due to security condition violations for the [Privileged PSS profile](https://kubernetes.io/docs/concepts/security/pod-security-standards) configured for the `assets` namespace.

Let us check if Deployment and Pod objects are created or not.

```bash test=false
$ kubectl -n assets get deploy
NAME     READY   UP-TO-DATE   AVAILABLE   AGE
assets   0/1     0            0           90s

$ kubectl -n assets get pod   
No resources found in assets namespace.
```
The above output indicates that PSA did not allow creation of Pods in the `assets` namespace, because the Pod security configuration violates Restricted PSS profile. This behaviour is same as what we saw earlier in the previous module.

## Add security controls to fix Pod security violations

Now, let's add some security controls to the Pod configuration to make it compliances to the Privileged PSS profile configured for the `assets` namespace.

```kustomization
security/pss-psa/restricted/restricted/deployment.yaml
Deployment/assets
```

Before applying the above changes, let us first delete the Deployment and re-create it with above changes.

```bash
$ kubectl -n assets delete deploy assets
Deployment.apps "assets" deleted
```

Run Kustomize to apply these changes, which we re-create the Deployment.

```bash timeout=180 hook=restricted-deploy-with-changes
$ kubectl apply -k /workspace/modules/security/pss-psa/restricted/restricted/
namespace/assets unchanged
serviceaccount/assets unchanged
configmap/assets unchanged
service/assets unchanged
deployment.apps/assets created
```
Now, Run the below commands to check PSA allows the creation of Deployment and Pod with the above changes in the  the `assets` namespace

```bash test=false
$ kubectl -n assets  get deploy                                                                    
NAME     READY   UP-TO-DATE   AVAILABLE   AGE
assets   1/1     1            1           3m2s
$ kubectl -n assets  get pod   
NAME                     READY   STATUS    RESTARTS   AGE
assets-8dd6fc8c6-9kptf   1/1     Running   0          3m6s
```
The above output indicates that PSA allowed since Pod security configuration confirms to the Restricted PSS profile.

Note that the above security permissions are not the comprehensive list of controls allowed under Restricted PSS profile. For detailed security controls allowed/disallowed under each PSS profile, refer to the [documentation](https://kubernetes.io/docs/concepts/security/pod-security-standards/#restricted)

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