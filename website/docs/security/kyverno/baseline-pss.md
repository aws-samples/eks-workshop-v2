---
title: "Enforcing Pod Security Standards"
sidebar_position: 62
---

As discussed in the introduction for [Pod Security Standards (PSS)](../pod-security-standards/) section, there are 3 pre-defined Policy levels, **Privileged**, **Baseline**, and **Restricted**. While it is recommended to setup a Restricted PSS, it can cause unintended behavior on the application level unless properly set. To get started it is recommended to setup a Baseline Policy that will prevent known Privileged escalations such as Containers accessing HostProcess, HostPath, HostPorts or allow traffic snooping for example, being possible to setup individual policies to restrict or disallow those privileged access to containers.

A Kyverno Baseline Policy will help to restrict all the known privileged escalation under a single policy, and also maintain and update the Policy regularly adding the latest found vulnerabilities to the Policy.

Privileged containers can do almost everything that the host can do and are often used in CI/CD pipelines to allow building and publishing Container images.
With the now fixed [CVE-2022-23648](https://github.com/containerd/containerd/security/advisories/GHSA-crp2-qrr5-8pq7) any bad actor, could escape the privileged container by abusing the Control Groups `release_agent` functionality to execute arbitrary commands on the container host.

In this lab, you will run a privileged Pod on our EKS cluster and check its privileged permissions. To do that, execute the following command.

```bash
$ kubectl run privileged-pod --image=centos --restart=Never --privileged --attach --rm --command -- /usr/sbin/capsh --print
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
pod "privileged-pod" deleted
```

Take sometime to check the existing admin capabilities like `cap_net_admin`, `cap_sys_admin`, and `cap_mac_admin`, or the `(unlocked)` Securebits, and also that this Pod is running with the `root` user `(uid=0)`.

In order to avoid such escalated privileged capabilities and avoid unauthorized use of above permissions, it's recommended to setup a Baseline Policy using Kyverno.

The baseline profile of the Pod Security Standards is a collection of the most basic and important steps that can be taken to secure Pods. Beginning with Kyverno 1.8, an entire profile may be assigned to the cluster through a single rule. To check more on the privileges blocked by Baseline Profile, please refer [here](https://kyverno.io/policies/#:~:text=Baseline%20Pod%20Security%20Standards,cluster%20through%20a%20single%20rule)

```file
manifests/modules/security/kyverno/baseline-policy/baseline-policy.yaml
```

Notice that he above policy is in `Enforce` mode, and will block any requests to create privileged Pod.

Go ahead and apply the Baseline Policy.

```bash
$ kubectl apply -f ~/environment/eks-workshop/modules/security/kyverno/baseline-policy/baseline-policy.yaml

clusterpolicy.kyverno.io/baseline-policy created
```

Now, try to run the privileged Pod again.

```bash
$ kubectl run privileged-pod --image=centos --restart=Never --privileged --attach --rm --command -- /usr/sbin/capsh --print
Error from server: admission webhook "validate.kyverno.svc-fail" denied the request: 

resource Pod/default/privileged-pod was blocked due to the following policies 

baseline-policy:
  baseline: |
    Validation rule 'baseline' failed. It violates PodSecurity "baseline:latest": ({Allowed:false ForbiddenReason:privileged ForbiddenDetail:container "privileged-pod" must not set securityContext.privileged=true})
```

As seen the creation failed, because it isn't in compliance with our Baseline Policy set on the Cluster.

### Note on Auto-Generated Policies

PSA operates at the Pod level, but in practice Pods are usually managed by Pod controllers, like Deployments. Having no indication of Pod security errors at the Pod controller level can make issues complex to troubleshoot. The PSA enforce mode is the only PSA mode that stops Pods from being created, however PSA enforcement doesn’t act at the Pod controller level. To improve this experience, it's recommended that PSA `warn` and `audit` modes are also used with `enforce`. With that PSA will indicate that the controller resources are trying to create Pods that would fail with the applied PSS level.

Using PaC solutions with Kubernetes presents another challenge of writing and maintaining policies to cover all the different resources used within clusters. With the [Kyverno Auto-Gen Rules for Pod Controllers](https://kyverno.io/docs/writing-policies/autogen/) feature, the Pod policies auto-generate associated Pod controller (Deployment, DaemonSet, etc.) policies. This Kyverno feature increases the expressive nature of policies and reduces the effort to maintain policies for associated resources. improving PSA user experience where controllers resources are not prevented from progressing, while the underlying Pods are.
