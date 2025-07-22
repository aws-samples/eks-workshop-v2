---
title: "Privileged PSS profile"
sidebar_position: 61
---

We'll start looking at PSS by exploring the Privileged profile, which is the most permissive and allows for known privilege escalations.

From Kubernetes version 1.23, by default, all PSA modes (i.e. enforce, audit and warn) are enabled for privileged PSS profile at the cluster level. That means, by default, PSA allows Deployments or Pods with Privileged PSS profile (i.e. absence of any restrictions) across all namespaces. These default settings provide less impact to clusters and reduce negative impact to applications. As we'll see, Namespace labels can be used to opt-in to more restrictive settings.

You can check that there are no PSA labels explicitly added to the `nginx` namespace, by default:

```bash
$ kubectl describe ns nginx
Name:         nginx
Labels:       app.kubernetes.io/created-by=eks-workshop
              kubernetes.io/metadata.name=nginx
Annotations:  <none>
Status:       Active

No resource quota.

No LimitRange resource.
```

As you see, the `nginx` namespace does not have any PSA labels attached.

Let us also check for currently running Deployment and Pod in the `nginx` namespace.

```bash
$ kubectl -n nginx get deployment
NAME     READY   UP-TO-DATE   AVAILABLE   AGE
nginx   1/1     1            1           5m24s
$ kubectl -n nginx get pod
NAME                     READY   STATUS    RESTARTS   AGE
nginx-ddb8f87dc-8z6l9   1/1     Running   0          5m24s
```

The YAML for the nginx Pod will show us the current security configuration:

```bash
$ kubectl -n nginx get deployment nginx -o yaml | yq '.spec.template.spec'
containers:
  - image: public.ecr.aws/docker/library/nginx:1.29
    imagePullPolicy: IfNotPresent
    name: nginx
    ports:
      - containerPort: 80
        protocol: TCP
    resources: {}
    securityContext:
      capabilities:
        drop:
          - ALL
      readOnlyRootFilesystem: false
    terminationMessagePath: /dev/termination-log
    terminationMessagePolicy: File
dnsPolicy: ClusterFirst
restartPolicy: Always
schedulerName: default-scheduler
securityContext: {}
terminationGracePeriodSeconds: 30
```

In the above Pod security configuration, the `securityContext` is nil at the Pod level. At the container level, the `securityContext` is configured to drop all the Linux capabilities and `readOnlyRootFilesystem` is set to false. The fact that the deployment and Pod are already running indicates that the PSA (configured for Privileged PSS profile by default) allowed above Pod security configuration.

But what are the other security controls this PSA allows? To check that, lets add some more permissions to the above Pod security configuration and check if the PSA still allows it or not in the `nginx` namespace. Specifically lets add the `privileged` and the `runAsUser:0` flags to the Pod, which means that it can access the hosts resources which is commonly required workloads like monitoring agents and service mesh sidecars, and also allowed to run as the `root` user:

```kustomization
modules/security/pss-psa/privileged-workload/deployment.yaml
Deployment/nginx
```

Run Kustomize to apply the above changes and check if PSA allows the Pod with the above security permissions.

```bash
$ kubectl apply -k ~/environment/eks-workshop/modules/security/pss-psa/privileged-workload
namespace/nginx unchanged
deployment.apps/nginx configured
```

Let us check if Deployment and Pod are re-created with above security permissions in the the `nginx` namespace

```bash
$ kubectl -n nginx get pod
NAME                      READY   STATUS    RESTARTS   AGE
nginx-64c49f848b-gmrtt   1/1     Running   0          9s

$ kubectl -n nginx exec $(kubectl -n nginx get pods -o name) -- whoami
root
```

This shows that the default PSA mode enabled for Privileged PSS profile is permissive and allows Pods to request elevated security permissions if necessary.

Note that the above security permissions are not the comprehensive list of controls allowed under Privileged PSS profile. For detailed security controls allowed/disallowed under each PSS profile, refer to the [documentation](https://kubernetes.io/docs/concepts/security/pod-security-standards/).
