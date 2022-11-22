---
title: "Run kube-bench as a debug job"
sidebar_position: 20
---

In this case, we are going to be running kube-bench as a k8s job with debug mode on.

```bash
$ kubectl apply -k /workspace/modules/security/kube-bench/debug
```

Run the job in your cluster

```file
security/kube-bench/debug/debug_job.yaml
```

Pod would be in the `Completed` state as the job would have completed the scan.
```bash
$ kubectl get pods
NAME                     READY   STATUS      RESTARTS   AGE
kube-bench-debug-5czbs   0/1     Completed   0          30s
```

Check the logs of the pod to determine the results of the scan
```bash
$ kubectl logs <kube-bench-debug-pod-name>
I1026 12:00:43.463034   22192 util.go:293] Kubernetes REST API Reported version: &{1 23+  v1.23.10-eks-15b7512}
I1026 12:00:43.463080   22192 common.go:350] Kubernetes version: "" to Benchmark version: "eks-1.1.0"
I1026 12:00:43.463087   22192 run.go:40] Checking targets [] for eks-1.1.0
I1026 12:00:43.463294   22192 common.go:273] Using config file: cfg/eks-1.1.0/config.yaml
I1026 12:00:43.463397   22192 run.go:75] Running tests from files [cfg/eks-1.1.0/controlplane.yaml cfg/eks-1.1.0/managedservices.yaml cfg/eks-1.1.0/master.yaml cfg/eks-1.1.0/node.yaml cfg/eks-1.1.0/policies.yaml]
I1026 12:00:43.463430   22192 common.go:79] Using test file: cfg/eks-1.1.0/controlplane.yaml
I1026 12:00:43.463470   22192 util.go:79] ps - proc: "kube-apiserver"
I1026 12:00:43.468096   22192 util.go:83] [/bin/ps -C kube-apiserver -o cmd --no-headers]: exit status 1
I1026 12:00:43.468110   22192 util.go:86] ps - returning: ""
I1026 12:00:43.468143   22192 util.go:227] reFirstWord.Match()
I1026 12:00:43.468149   22192 util.go:257] executable 'kube-apiserver' not running
I1026 12:00:43.468155   22192 util.go:79] ps - proc: "hyperkube"
I1026 12:00:43.472543   22192 util.go:83] [/bin/ps -C hyperkube -o cmd --no-headers]: exit status 1
I1026 12:00:43.472556   22192 util.go:86] ps - returning: ""
I1026 12:00:43.472609   22192 util.go:227] reFirstWord.Match()
I1026 12:00:43.472615   22192 util.go:257] executable 'hyperkube apiserver' not running
I1026 12:00:43.472620   22192 util.go:79] ps - proc: "hyperkube"
I1026 12:00:43.476459   22192 util.go:83] [/bin/ps -C hyperkube -o cmd --no-headers]: exit status 1
I1026 12:00:43.476472   22192 util.go:86] ps - returning: ""
I1026 12:00:43.476501   22192 util.go:227] reFirstWord.Match()
I1026 12:00:43.476507   22192 util.go:257] executable 'hyperkube kube-apiserver' not running
I1026 12:00:43.476512   22192 util.go:79] ps - proc: "apiserver"
I1026 12:00:43.480302   22192 util.go:83] [/bin/ps -C apiserver -o cmd --no-headers]: exit status 1
I1026 12:00:43.480318   22192 util.go:86] ps - returning: ""
I1026 12:00:43.480343   22192 util.go:227] reFirstWord.Match()
I1026 12:00:43.480349   22192 util.go:257] executable 'apiserver' not running
I1026 12:00:43.480366   22192 util.go:106] 
Unable to detect running programs for component "apiserver"
The following "master node" programs have been searched, but none of them have been found:
        - kube-apiserver
        - hyperkube apiserver
        - hyperkube kube-apiserver
        - apiserver

 == Summary master ==
0 checks PASS
0 checks FAIL
0 checks WARN
0 checks INFO

[INFO] 2 Control Plane Configuration
[INFO] 2.1 Logging
[WARN] 2.1.1 Enable audit logs (Manual)

== Remediations controlplane ==
2.1.1 audit test did not run: No tests defined

== Summary controlplane ==
0 checks PASS
0 checks FAIL
1 checks WARN
0 checks INFO

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

== Summary node ==
14 checks PASS
0 checks FAIL
2 checks WARN
0 checks INFO
```
