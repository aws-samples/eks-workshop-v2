---
title : "Baselining Pod Security Standards"
weight : 134
---

As Discussed, in our Introduction,  Policy levels are defined in **3 types 1/Baseline 2/Restricted & 3/Priveleged.** While it is recommended to setup a Restricted PSS, it can cause unknown issues on the Application level unless set properly. To get started it is recommended to setup a Baseline Policy that will prevent known Privileged escalations such as Containers accessing HostProcess, HostPath, Access to Host Ports to allow snopping of traffic and much more. 

To get more details on the Baseline PSS rules, Please refer [here.](https://kubernetes.io/docs/concepts/security/pod-security-standards/#:~:text=The%20Baseline%20policy%20is%20aimed,developers%20of%20non%2Dcritical%20applications.)


We can setup individual policies to restrict/disallow the privilege access to containers mentioned above. A Kyverno Baseline Policy will help to restrict all the known privileged escalation under a single policy. Kyverno also maintains and updates the Policy regularly which adds the latest vulnerabilities to the Policy.

Generally, Privileged containers are often used in CI/CD pipelines to allow for building and publishing Container images. 
With the now fixed [CVE-2022-23648](https://github.com/containerd/containerd/security/advisories/GHSA-crp2-qrr5-8pq7) any bad actor, could escape the privileged container by abusing the Control Groups ```release_agent``` functionality to execute arbitrary commands on the container host. 

A privileged container, can do almost everything that the host can do. In our example, we will create a privileged Pod on our EKS cluster. 

```
apiVersion: v1
kind: Pod
metadata:
  name: privileged-pod
spec:
  containers:
  - name: privileged-pod
    image: centos
    securityContext:
      privileged: true
    command: [ "sh", "-c", "sleep 1000" ]
```

We will create the pod using ```Kubectl apply -f <file_name>```. Sample Output below.

```yaml
pod/privileged-pod created
```

Next we will exec in to the pod & check the privileges the pod is granted.

```
kubectl exec -it privileged-pod -- bash 
```

> Once we are able to access the shell running inside the container. Run ```capsh --print``` to check the privileges.

```
[root@privileged-pod /]# capsh --print
Current: = cap_chown,cap_dac_override,cap_dac_read_search,cap_fowner,cap_fsetid,cap_kill,cap_setgid,cap_setuid,cap_setpcap,cap_linux_immutable,cap_net_bind_service,cap_net_broadcast,cap_net_admin,cap_net_raw,cap_ipc_lock,cap_ipc_owner,cap_sys_module,cap_sys_rawio,cap_sys_chroot,cap_sys_ptrace,cap_sys_pacct,cap_sys_admin,cap_sys_boot,cap_sys_nice,cap_sys_resource,cap_sys_time,cap_sys_tty_config,cap_mknod,cap_lease,cap_audit_write,cap_audit_control,cap_setfcap,cap_mac_override,cap_mac_admin,cap_syslog,cap_wake_alarm,cap_block_suspend,cap_audit_read,38,39,40+ep
Bounding set =cap_chown,cap_dac_override,cap_dac_read_search,cap_fowner,cap_fsetid,cap_kill,cap_setgid,cap_setuid,cap_setpcap,cap_linux_immutable,cap_net_bind_service,cap_net_broadcast,cap_net_admin,cap_net_raw,cap_ipc_lock,cap_ipc_owner,cap_sys_module,cap_sys_rawio,cap_sys_chroot,cap_sys_ptrace,cap_sys_pacct,cap_sys_admin,cap_sys_boot,cap_sys_nice,cap_sys_resource,cap_sys_time,cap_sys_tty_config,cap_mknod,cap_lease,cap_audit_write,cap_audit_control,cap_setfcap,cap_mac_override,cap_mac_admin,cap_syslog,cap_wake_alarm,cap_block_suspend,cap_audit_read,38,39,40
Ambient set =
Securebits: 00/0x0/1'b0
 secure-noroot: no (unlocked)
 secure-no-suid-fixup: no (unlocked)
 secure-keep-caps: no (unlocked)
 secure-no-ambient-raise: no (unlocked)
uid=0(root)
gid=0(root)
groups=0(root)
[root@privileged-pod /]# 
```

> You can also notice, that the container is running as the **Root** User as default.

In order to avoid such escalated privileged situations, and avoid unauthorised use of above mentioned permissions. We will setup a Baseline Policy using Kyverno. 

The baseline profile of the Pod Security Standards is a collection of the most basic and important steps that can be taken to secure Pods. Beginning with Kyverno 1.8, an entire profile may be assigned to the cluster through a single rule. To check more on the privileges blocked by Baseline Profile, please refer [here](https://kyverno.io/policies/#:~:text=Baseline%20Pod%20Security%20Standards,cluster%20through%20a%20single%20rule)


```
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: baseline-policy
spec:
  background: true
  validationFailureAction: Enforce
  rules:
  - name: baseline
    match:
      any:
      - resources:
          kinds:
          - Pod
    validate:
      podSecurity:
        level: baseline
        version: latest
```

> Note: The above policy is in Enforce mode, and will block the requests to create any privileged pod.

We will apply the above policy using the `Kubectl apply -f <file_name>.yaml` command & run an Application on our EKS Cluster.

We will create a sample pod, to check the policy Implementation

```
apiVersion: v1
kind: Pod
metadata:
  name: privileged-pod-02
spec:
  hostIPC: true 
  containers:
  - name: privileged-pod-02
    image: centos
    securityContext:
      privileged: true
    command: [ "sh", "-c", "sleep 1000" ]
```

> **hostIPC**: The Host IPC namespace controls whether a pod's containers can be shared with the underlying host

We will create the pod using ```Kubectl apply -f <file_name>```. Our Pod Creation will fail, because it isn't in compliance with our BaselinePolicy set on the Cluster.

```
Error from server: error when creating "priv.yaml": admission webhook "validate.kyverno.svc-fail" denied the request: 

resource Pod/default/privileged-pod-02 was blocked due to the following policies 

baseline-policy:
  baseline: |
    Validation rule 'baseline' failed. It violates PodSecurity "baseline:latest": ({Allowed:false ForbiddenReason:host namespaces ForbiddenDetail:hostIPC=true})
    ({Allowed:false ForbiddenReason:privileged ForbiddenDetail:container "privileged-pod-02" must not set securityContext.privileged=true})
podsecurity-subrule-baseline:
  baseline: |
    Validation rule 'baseline' failed. It violates PodSecurity "baseline:latest": ({Allowed:false ForbiddenReason:host namespaces ForbiddenDetail:hostIPC=true})
    ({Allowed:false ForbiddenReason:privileged ForbiddenDetail:container "privileged-pod-02" must not set securityContext.privileged=true})
```

## Note on Auto-Generated Policies:
---

PSA operates at the pod level, but in practice pods are usually managed by pod controllers, like Deployments. Having no indication of pod security errors at the pod controller level makes issues complex to troubleshoot. The PSA enforce mode is the only PSA mode that stops pods from being created; however, PSA enforce doesn’t act on controller resources that create pods. To help this user experience, we recommend that PSA ```warn``` and ```audit``` modes are also used with ```enforce```; PSA warn and audit modes will at least indicate that pod-creating controller resources are trying to create pods that would otherwise fail the applied PSS level. This user experience can present a challenge to adopters of the PSA/PSS features.

Using PaC solutions with Kubernetes presents another challenge: writing and maintaining policies to cover all the different Kubernetes resources used within clusters. With the [Kyverno Auto-Gen Rules for Pod Controllers](https://kyverno.io/docs/writing-policies/autogen/) feature, the above pod policies auto-generate associated pod controller (Deployment, DaemonSet, etc.) policies. This Kyverno feature increases the expressive nature of policies, and reduces the effort to maintain policies for associated resources. These additional auto-generated policies also improve the above-mentioned PSA user experience where pod-creating resources are not prevented from progressing, while the underlying pods are prevented.

