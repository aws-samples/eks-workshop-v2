---
title: "Run kube-bench as a debug job"
sidebar_position: 30
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
$ kubectl logs kube-bench-debug-5czbs
I1025 15:53:50.293436   27688 util.go:293] Kubernetes REST API Reported version: &{1 23+  v1.23.10-eks-15b7512}
I1025 15:53:50.293526   27688 common.go:350] Kubernetes version: "" to Benchmark version: "eks-1.0.1"
I1025 15:53:50.293537   27688 root.go:76] Running checks for benchmark eks-1.0.1
I1025 15:53:50.293543   27688 common.go:365] Checking if the current node is running master components
I1025 15:53:50.293585   27688 util.go:79] ps - proc: "kube-apiserver"
I1025 15:53:50.298234   27688 util.go:83] [/bin/ps -C kube-apiserver -o cmd --no-headers]: exit status 1
I1025 15:53:50.298249   27688 util.go:86] ps - returning: ""
I1025 15:53:50.298272   27688 util.go:227] reFirstWord.Match()
I1025 15:53:50.298278   27688 util.go:257] executable 'kube-apiserver' not running
I1025 15:53:50.298284   27688 util.go:79] ps - proc: "hyperkube"
I1025 15:53:50.302506   27688 util.go:83] [/bin/ps -C hyperkube -o cmd --no-headers]: exit status 1
I1025 15:53:50.302522   27688 util.go:86] ps - returning: ""
I1025 15:53:50.302547   27688 util.go:227] reFirstWord.Match()
I1025 15:53:50.302552   27688 util.go:257] executable 'hyperkube apiserver' not running
I1025 15:53:50.302557   27688 util.go:79] ps - proc: "hyperkube"
I1025 15:53:50.306291   27688 util.go:83] [/bin/ps -C hyperkube -o cmd --no-headers]: exit status 1
I1025 15:53:50.306304   27688 util.go:86] ps - returning: ""
I1025 15:53:50.306338   27688 util.go:227] reFirstWord.Match()
I1025 15:53:50.306344   27688 util.go:257] executable 'hyperkube kube-apiserver' not running
I1025 15:53:50.306349   27688 util.go:79] ps - proc: "apiserver"
I1025 15:53:50.310100   27688 util.go:83] [/bin/ps -C apiserver -o cmd --no-headers]: exit status 1
I1025 15:53:50.310113   27688 util.go:86] ps - returning: ""
I1025 15:53:50.310132   27688 util.go:227] reFirstWord.Match()
I1025 15:53:50.310138   27688 util.go:257] executable 'apiserver' not running
I1025 15:53:50.310144   27688 util.go:79] ps - proc: "openshift"
I1025 15:53:50.313840   27688 util.go:83] [/bin/ps -C openshift -o cmd --no-headers]: exit status 1
I1025 15:53:50.313852   27688 util.go:86] ps - returning: ""
I1025 15:53:50.313894   27688 util.go:227] reFirstWord.Match()
I1025 15:53:50.313900   27688 util.go:257] executable 'openshift start master api' not running
I1025 15:53:50.313905   27688 util.go:79] ps - proc: "hypershift"
I1025 15:53:50.317677   27688 util.go:83] [/bin/ps -C hypershift -o cmd --no-headers]: exit status 1
I1025 15:53:50.317696   27688 util.go:86] ps - returning: ""
I1025 15:53:50.317730   27688 util.go:227] reFirstWord.Match()
I1025 15:53:50.317735   27688 util.go:257] executable 'hypershift openshift-kube-apiserver' not running
I1025 15:53:50.317756   27688 util.go:106] 
Unable to detect running programs for component "apiserver"
The following "master node" programs have been searched, but none of them have been found:
        - kube-apiserver
        - hyperkube apiserver
        - hyperkube kube-apiserver
        - apiserver
        - openshift start master api
        - hypershift openshift-kube-apiserver


These program names are provided in the config.yaml, section 'master.apiserver.bins'
I1025 15:53:50.317764   27688 common.go:374] Failed to find master binaries: unable to detect running programs for component "apiserver"
I1025 15:53:50.317773   27688 root.go:93] == Skipping master checks ==
I1025 15:53:50.317851   27688 root.go:106] == Skipping etcd checks ==
I1025 15:53:50.317860   27688 root.go:109] == Running node checks ==
I1025 15:53:50.317866   27688 util.go:126] Looking for config specific CIS version "eks-1.0.1"
I1025 15:53:50.317875   27688 util.go:130] Looking for file: cfg/eks-1.0.1/node.yaml
I1025 15:53:50.318005   27688 common.go:273] Using config file: cfg/eks-1.0.1/config.yaml
I1025 15:53:50.318044   27688 common.go:79] Using test file: cfg/eks-1.0.1/node.yaml
I1025 15:53:50.318080   27688 util.go:79] ps - proc: "hyperkube"
I1025 15:53:50.321702   27688 util.go:83] [/bin/ps -C hyperkube -o cmd --no-headers]: exit status 1
I1025 15:53:50.321715   27688 util.go:86] ps - returning: ""
I1025 15:53:50.321736   27688 util.go:227] reFirstWord.Match()
I1025 15:53:50.321745   27688 util.go:257] executable 'hyperkube kubelet' not running
I1025 15:53:50.321751   27688 util.go:79] ps - proc: "kubelet"
I1025 15:53:50.325552   27688 util.go:86] ps - returning: "/usr/bin/kubelet --cloud-provider aws --config /etc/kubernetes/kubelet/kubelet-config.json --kubeconfig /var/lib/kubelet/kubeconfig --container-runtime docker --network-plugin cni --node-ip=10.42.11.242 --pod-infra-container-image=602401143452.dkr.ecr.us-east-2.amazonaws.com/eks/pause:3.5 --v=2 --max-pods=110\n"
I1025 15:53:50.325587   27688 util.go:227] reFirstWord.Match(/usr/bin/kubelet --cloud-provider aws --config /etc/kubernetes/kubelet/kubelet-config.json --kubeconfig /var/lib/kubelet/kubeconfig --container-runtime docker --network-plugin cni --node-ip=10.42.11.242 --pod-infra-container-image=602401143452.dkr.ecr.us-east-2.amazonaws.com/eks/pause:3.5 --v=2 --max-pods=110)
I1025 15:53:50.325599   27688 util.go:115] Component kubelet uses running binary kubelet
I1025 15:53:50.325623   27688 util.go:79] ps - proc: "kube-proxy"
I1025 15:53:50.329265   27688 util.go:86] ps - returning: "kube-proxy --v=2 --config=/var/lib/kube-proxy-config/config --hostname-override=ip-10-42-11-242.us-east-2.compute.internal\n"
I1025 15:53:50.329292   27688 util.go:227] reFirstWord.Match(kube-proxy --v=2 --config=/var/lib/kube-proxy-config/config --hostname-override=ip-10-42-11-242.us-east-2.compute.internal)


== Summary total ==
14 checks PASS
0 checks FAIL
37 checks WARN
0 checks INFO
```