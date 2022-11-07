---
title: "Privileged PSS Profile"
sidebar_position: 10
---

In the section, we will look at the followng scenario.

#### Default PSA Modes Enabled for Privileged PSS Profile at the Cluster Level.

From Kubernetes version 1.23, by default, all PSA modes (i.e. enforce, audit and warn) are enabled for privileged PSS profile at the cluster level. That means, by default, PSA allows deployments or pods with Privileged PSS profile (i.e. absence of any restrictions) across all namespaces.
These default settings provide less impact to clusters and reduce negative impact to applications. As we will see, Namespace labels can be used to opt-in to more restrictive settings.

Run the following command to setup the EKS cluster for this module:

```bash timeout=300 wait=30
$ reset-environment 
```
Let us take one of the namespaces in our sample application, say `assets` namespace to demonstrate how the default PSA modes work for the Privileged PSS profile.
## Review existing pod security configuration

Let's ensure that there are no PSA labels added to the `assets` namespace, by default.

You can check current lables for namespace using below command.

```bash  timeout=60 hook=privileged-namespace-no-labels
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

Let us also check for currently running deployment and pod in the `assets` namespace.

```bash test=false
$ kubectl -n assets get deploy
NAME     READY   UP-TO-DATE   AVAILABLE   AGE
assets   1/1     1            1           5m24s

$ kubectl -n assets  get pod
NAME                     READY   STATUS    RESTARTS   AGE
assets-ddb8f87dc-8z6l9   1/1     Running   0          5m24s
```

Let us also review the security configuration applied currently for the above pod in `assets` namespace.

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

In the above pod security configuration, the `securityContext` is nil at the pod level. At the container level, the `securityContext` is configured to drop all the linux capabilities and `readOnlyRootFilesystem` is set to false.

The fact that the deployment and pod are already running indicates that the PSA (configured for Privileged PSS profile by default) allowed above pod security configuration.

But what are the other security controls does PSA allows by default?. To check that, let us add some more permissions to the above pod security configuration and check if PSA allows it or not in the `assets` namespace.

## Add additional security permissions to the pod

We will be adding following additional permissions and capabilities to our pod configuration.

```kustomization
security/pss-psa/priveleged/deployment.yaml
Deployment/assets
```
Before we deploy our changes, let us first delete the existing deployment and then re-create it with the above changes.

```bash
$ kubectl -n assets delete deploy assets
deployment.apps "assets" deleted
```

Run Kustomize to apply the above changes and check if PSA allows the pod with the above security permissions.


```bash  timeout=180 hook=privileged-deploy-with-changes
$ kubectl apply -k /workspace/modules/security/pss-psa/priveleged/
namespace/assets unchanged
serviceaccount/assets unchanged
configmap/assets unchanged
service/assets unchanged
deployment.apps/assets created
```
Let us check if deployment and pod are re-created with above security permissions in the the `assets` namespace

```bash test=false
$ kubectl -n assets get deploy
NAME     READY   UP-TO-DATE   AVAILABLE   AGE
assets   1/1     1            1           42s

$ kubectl -n assets  get pod
NAME                      READY   STATUS    RESTARTS   AGE
assets-64c49f848b-gmrtt   1/1     Running   0          9s
```

Let us review the security configuration for the re-created pod with all of our changes.

```bash test=false
$ kubectl -n assets get deploy assets -oyaml
....
        securityContext:
          allowPrivilegeEscalation: true
          capabilities:
            drop:
            - DAC_OVERRIDE
          privileged: true
          readOnlyRootFilesystem: false
          runAsNonRoot: false
        terminationMessagePath: /dev/termination-log
        terminationMessagePolicy: File
        volumeMounts:
        - mountPath: /tmp
          name: tmp-volume
      dnsPolicy: ClusterFirst
      hostIPC: true
      hostNetwork: true
      hostPID: true
      restartPolicy: Always
      schedulerName: default-scheduler
      securityContext:
        runAsNonRoot: false
...        
```

This shows that default PSA mode enabled for Privileged PSS profile allows many security permissions as shown above.
 
Note that the above security permissions are not the comprehensive list of controls allowed under Privileged PSS profile. For detailed security controls allowed/disallowed under each PSS profile, refer to the [documentation](https://kubernetes.io/docs/concepts/security/pod-security-standards/)

## Cleanup

Let us revert the changes by first deleting the deployment. 

```bash
$ kubectl -n assets delete deploy assets
deployment.apps "assets" deleted

```
Then re-deploy it from the original manifest.

```bash
$ kubectl apply -k /workspace/manifests/assets
namespace/assets unchanged
serviceaccount/assets unchanged
configmap/assets unchanged
service/assets unchanged
deployment.apps/assets created

```
