---
title: "Introduction"
sidebar_position: 10
---

Run the following command to setup the EKS cluster for this module:

```bash timeout=300 wait=30
$ reset-environment
```

List the EKS Cluster nodes

```bash
$ kubectl get nodes -o wide
NAME                                         STATUS   ROLES    AGE    VERSION               INTERNAL-IP    EXTERNAL-IP   OS-IMAGE         KERNEL-VERSION                 CONTAINER-RUNTIME
ip-10-42-10-118.us-east-2.compute.internal   Ready    <none>   108m   v1.23.9-eks-ba74326   10.42.10.118   <none>        Amazon Linux 2   5.4.209-116.367.amzn2.x86_64   docker://20.10.17
ip-10-42-11-242.us-east-2.compute.internal   Ready    <none>   109m   v1.23.9-eks-ba74326   10.42.11.242   <none>        Amazon Linux 2   5.4.209-116.367.amzn2.x86_64   docker://20.10.17
ip-10-42-12-41.us-east-2.compute.internal    Ready    <none>   109m   v1.23.9-eks-ba74326   10.42.12.41    <none>        Amazon Linux 2   5.4.209-116.367.amzn2.x86_64   docker://20.10.17
```

SSH into the nodes

  Ssh (using SSM) via the AWS Console by clicking ‘Connect’->'Session Manager'

Install `kube-bench`

1. Set Kube-bench URL in EKS node.
```bash
$ KUBEBENCH_URL=$(curl -s https://api.github.com/repos/aquasecurity/kube-bench/releases/latest | jq -r '.assets[] | select(.name | contains("amd64.rpm")) | .browser_download_url')
```
2. Download and install kube-bench using yum
```bash
$ sudo yum install -y $KUBEBENCH_URL
```

3. Run assessment against `eks-1.1.0` based on CIS Amazon EKS Benchmark node assessments.
```bash
$ kube-bench --benchmark eks-1.1.0
[INFO] 3 Worker Node Security Configuration
[INFO] 3.1 Worker Node Configuration Files
[PASS] 3.1.1 Ensure that the kubeconfig file permissions are set to 644 or more restrictive (Manual)
[PASS] 3.1.2 Ensure that the kubelet kubeconfig file ownership is set to root:root (Manual)
[PASS] 3.1.3 Ensure that the kubelet configuration file has permissions set to 644 or more restrictive (Manual)
[PASS] 3.1.4 Ensure that the kubelet configuration file ownership is set to root:root (Manual)
[INFO] 3.2 Kubelet
[PASS] 3.2.1 Ensure that the --anonymous-auth argument is set to false (Automated)
[PASS] 3.2.2 Ensure that the --authorization-mode argument is not set to AlwaysAllow (Automated)
[PASS] 3.2.3 Ensure that the --client-ca-file argument is set as appropriate (Manual)
[PASS] 3.2.4 Ensure that the --read-only-port argument is set to 0 (Manual)
[PASS] 3.2.5 Ensure that the --streaming-connection-idle-timeout argument is not set to 0 (Manual)
[PASS] 3.2.6 Ensure that the --protect-kernel-defaults argument is set to true (Automated)
[PASS] 3.2.7 Ensure that the --make-iptables-util-chains argument is set to true (Automated)
[PASS] 3.2.8 Ensure that the --hostname-override argument is not set (Manual)
[WARN] 3.2.9 Ensure that the --eventRecordQPS argument is set to 0 or a level which ensures appropriate event capture (Automated)
[PASS] 3.2.10 Ensure that the --rotate-certificates argument is not set to false (Manual)
[PASS] 3.2.11 Ensure that the RotateKubeletServerCertificate argument is set to true (Manual)
[INFO] 3.3 Container Optimized OS
[WARN] 3.3.1 Prefer using Container-Optimized OS when possible (Manual)

== Remediations node ==
3.2.9 If using a Kubelet config file, edit the file to set eventRecordQPS: to an appropriate level.
If using command line arguments, edit the kubelet service file
/etc/systemd/system/kubelet.service on each worker node and
set the below parameter in KUBELET_SYSTEM_PODS_ARGS variable.
Based on your system, restart the kubelet service. For example:
systemctl daemon-reload
systemctl restart kubelet.service

3.3.1 audit test did not run: No tests defined

== Summary node ==
14 checks PASS
0 checks FAIL
2 checks WARN
0 checks INFO
```

Clean-up

Uninstall `kube-bench`
```bash
$ sudo yum remove kube-bench -y
```

Exit out of the node
```bash
$ exit
```