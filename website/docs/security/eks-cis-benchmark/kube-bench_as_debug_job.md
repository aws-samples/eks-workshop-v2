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


These program names are provided in the config.yaml, section 'master.apiserver.bins'
I1026 12:00:43.480375   22192 common.go:92] failed to get a set of executables needed for tests: unable to detect running programs for component "apiserver"
I1026 12:00:43.480426   22192 util.go:196] Missing config file for apiserver
I1026 12:00:43.480444   22192 util.go:196] Missing service file for apiserver
I1026 12:00:43.480462   22192 util.go:196] Missing kubeconfig file for apiserver
I1026 12:00:43.480480   22192 util.go:196] Missing ca file for apiserver
I1026 12:00:43.480488   22192 util.go:387] Substituting $apiserverconf with 'apiserver'
I1026 12:00:43.480495   22192 util.go:387] Substituting $apiserversvc with 'apiserver'
I1026 12:00:43.480501   22192 util.go:387] Substituting $apiserverkubeconfig with 'apiserver'
I1026 12:00:43.480506   22192 util.go:387] Substituting $apiservercafile with 'apiserver'
I1026 12:00:43.480720   22192 check.go:110] -----   Running check 2.1.1   -----
I1026 12:00:43.480736   22192 check.go:145] No tests defined
I1026 12:00:43.480774   22192 common.go:79] Using test file: cfg/eks-1.1.0/managedservices.yaml
I1026 12:00:43.481117   22192 check.go:110] -----   Running check 5.1.1   -----
I1026 12:00:43.481133   22192 check.go:133] Test marked as a manual test
I1026 12:00:43.481138   22192 check.go:110] -----   Running check 5.1.2   -----
I1026 12:00:43.481143   22192 check.go:133] Test marked as a manual test
I1026 12:00:43.481147   22192 check.go:110] -----   Running check 5.1.3   -----
I1026 12:00:43.481159   22192 check.go:133] Test marked as a manual test
I1026 12:00:43.481163   22192 check.go:110] -----   Running check 5.1.4   -----
I1026 12:00:43.481168   22192 check.go:133] Test marked as a manual test
I1026 12:00:43.481172   22192 check.go:110] -----   Running check 5.2.1   -----
I1026 12:00:43.481177   22192 check.go:133] Test marked as a manual test
I1026 12:00:43.481182   22192 check.go:110] -----   Running check 5.3.1   -----
I1026 12:00:43.481186   22192 check.go:133] Test marked as a manual test
I1026 12:00:43.481190   22192 check.go:110] -----   Running check 5.4.1   -----
I1026 12:00:43.481195   22192 check.go:133] Test marked as a manual test
I1026 12:00:43.481199   22192 check.go:110] -----   Running check 5.4.2   -----
I1026 12:00:43.481203   22192 check.go:133] Test marked as a manual test
I1026 12:00:43.481207   22192 check.go:110] -----   Running check 5.4.3   -----
I1026 12:00:43.481212   22192 check.go:133] Test marked as a manual test
I1026 12:00:43.481216   22192 check.go:110] -----   Running check 5.4.4   -----
I1026 12:00:43.481221   22192 check.go:133] Test marked as a manual test
I1026 12:00:43.481225   22192 check.go:110] -----   Running check 5.4.5   -----
I1026 12:00:43.481233   22192 check.go:133] Test marked as a manual test
I1026 12:00:43.481238   22192 check.go:110] -----   Running check 5.5.1   -----
I1026 12:00:43.481247   22192 check.go:133] Test marked as a manual test
I1026 12:00:43.481251   22192 check.go:110] -----   Running check 5.6.1   -----
I1026 12:00:43.481256   22192 check.go:133] Test marked as a manual test
I1026 12:00:43.481281   22192 common.go:79] Using test file: cfg/eks-1.1.0/master.yaml
I1026 12:00:43.481327   22192 util.go:79] ps - proc: "kube-apiserver"
I1026 12:00:43.485223   22192 util.go:83] [/bin/ps -C kube-apiserver -o cmd --no-headers]: exit status 1
I1026 12:00:43.485235   22192 util.go:86] ps - returning: ""
I1026 12:00:43.485258   22192 util.go:227] reFirstWord.Match()
I1026 12:00:43.485263   22192 util.go:257] executable 'kube-apiserver' not running
I1026 12:00:43.485269   22192 util.go:79] ps - proc: "hyperkube"
I1026 12:00:43.489005   22192 util.go:83] [/bin/ps -C hyperkube -o cmd --no-headers]: exit status 1
I1026 12:00:43.489017   22192 util.go:86] ps - returning: ""
I1026 12:00:43.489046   22192 util.go:227] reFirstWord.Match()
I1026 12:00:43.489052   22192 util.go:257] executable 'hyperkube apiserver' not running
I1026 12:00:43.489057   22192 util.go:79] ps - proc: "hyperkube"
I1026 12:00:43.492841   22192 util.go:83] [/bin/ps -C hyperkube -o cmd --no-headers]: exit status 1
I1026 12:00:43.492860   22192 util.go:86] ps - returning: ""
I1026 12:00:43.492894   22192 util.go:227] reFirstWord.Match()
I1026 12:00:43.492900   22192 util.go:257] executable 'hyperkube kube-apiserver' not running
I1026 12:00:43.492906   22192 util.go:79] ps - proc: "apiserver"
I1026 12:00:43.496866   22192 util.go:83] [/bin/ps -C apiserver -o cmd --no-headers]: exit status 1
I1026 12:00:43.496878   22192 util.go:86] ps - returning: ""
I1026 12:00:43.496901   22192 util.go:227] reFirstWord.Match()
I1026 12:00:43.496915   22192 util.go:257] executable 'apiserver' not running
I1026 12:00:43.496920   22192 util.go:79] ps - proc: "openshift"
I1026 12:00:43.500729   22192 util.go:83] [/bin/ps -C openshift -o cmd --no-headers]: exit status 1
I1026 12:00:43.500742   22192 util.go:86] ps - returning: ""
I1026 12:00:43.500776   22192 util.go:227] reFirstWord.Match()
I1026 12:00:43.500781   22192 util.go:257] executable 'openshift start master api' not running
I1026 12:00:43.500786   22192 util.go:79] ps - proc: "hypershift"
I1026 12:00:43.504543   22192 util.go:83] [/bin/ps -C hypershift -o cmd --no-headers]: exit status 1
I1026 12:00:43.504554   22192 util.go:86] ps - returning: ""
I1026 12:00:43.504617   22192 util.go:227] reFirstWord.Match()
I1026 12:00:43.504622   22192 util.go:257] executable 'hypershift openshift-kube-apiserver' not running
I1026 12:00:43.504639   22192 util.go:106] 
Unable to detect running programs for component "apiserver"
The following "master node" programs have been searched, but none of them have been found:
        - kube-apiserver
        - hyperkube apiserver
        - hyperkube kube-apiserver
        - apiserver
        - openshift start master api
        - hypershift openshift-kube-apiserver


These program names are provided in the config.yaml, section 'master.apiserver.bins'
I1026 12:00:43.504649   22192 common.go:92] failed to get a set of executables needed for tests: unable to detect running programs for component "apiserver"
I1026 12:00:43.504718   22192 util.go:193] Using default config file name '/etc/kubernetes/manifests/kube-apiserver.yaml' for component apiserver
I1026 12:00:43.504757   22192 util.go:193] Using default config file name '/etc/kubernetes/manifests/kube-scheduler.yaml' for component scheduler
I1026 12:00:43.504799   22192 util.go:193] Using default config file name '/etc/kubernetes/manifests/kube-controller-manager.yaml' for component controllermanager
I1026 12:00:43.504847   22192 util.go:193] Using default config file name '/etc/kubernetes/manifests/etcd.yaml' for component etcd
I1026 12:00:43.504863   22192 util.go:193] Using default config file name '/etc/sysconfig/flanneld' for component flanneld
I1026 12:00:43.504879   22192 util.go:193] Using default config file name '/etc/kubernetes/config' for component kubernetes
I1026 12:00:43.504899   22192 util.go:196] Missing config file for kubelet
I1026 12:00:43.504915   22192 util.go:196] Missing service file for apiserver
I1026 12:00:43.504937   22192 util.go:196] Missing service file for scheduler
I1026 12:00:43.504956   22192 util.go:196] Missing service file for controllermanager
I1026 12:00:43.504970   22192 util.go:196] Missing service file for etcd
I1026 12:00:43.504985   22192 util.go:196] Missing service file for flanneld
I1026 12:00:43.504998   22192 util.go:196] Missing service file for kubernetes
I1026 12:00:43.505021   22192 util.go:196] Missing service file for kubelet
I1026 12:00:43.505040   22192 util.go:196] Missing kubeconfig file for apiserver
I1026 12:00:43.505082   22192 util.go:193] Using default kubeconfig file name '/etc/kubernetes/scheduler.conf' for component scheduler
I1026 12:00:43.505116   22192 util.go:193] Using default kubeconfig file name '/etc/kubernetes/controller-manager.conf' for component controllermanager
I1026 12:00:43.505137   22192 util.go:196] Missing kubeconfig file for etcd
I1026 12:00:43.505158   22192 util.go:196] Missing kubeconfig file for flanneld
I1026 12:00:43.505178   22192 util.go:196] Missing kubeconfig file for kubernetes
I1026 12:00:43.505196   22192 util.go:196] Missing kubeconfig file for kubelet
I1026 12:00:43.505215   22192 util.go:196] Missing ca file for apiserver
I1026 12:00:43.505231   22192 util.go:196] Missing ca file for scheduler
I1026 12:00:43.505252   22192 util.go:196] Missing ca file for controllermanager
I1026 12:00:43.505268   22192 util.go:196] Missing ca file for etcd
I1026 12:00:43.505283   22192 util.go:196] Missing ca file for flanneld
I1026 12:00:43.505296   22192 util.go:196] Missing ca file for kubernetes
I1026 12:00:43.505315   22192 util.go:196] Missing ca file for kubelet
I1026 12:00:43.505323   22192 util.go:387] Substituting $flanneldconf with '/etc/sysconfig/flanneld'
I1026 12:00:43.505330   22192 util.go:387] Substituting $kubernetesconf with '/etc/kubernetes/config'
I1026 12:00:43.505336   22192 util.go:387] Substituting $kubeletconf with 'kubelet'
I1026 12:00:43.505341   22192 util.go:387] Substituting $apiserverconf with '/etc/kubernetes/manifests/kube-apiserver.yaml'
I1026 12:00:43.505353   22192 util.go:387] Substituting $schedulerconf with '/etc/kubernetes/manifests/kube-scheduler.yaml'
I1026 12:00:43.505359   22192 util.go:387] Substituting $controllermanagerconf with '/etc/kubernetes/manifests/kube-controller-manager.yaml'
I1026 12:00:43.505364   22192 util.go:387] Substituting $etcdconf with '/etc/kubernetes/manifests/etcd.yaml'
I1026 12:00:43.505370   22192 util.go:387] Substituting $schedulersvc with 'scheduler'
I1026 12:00:43.505374   22192 util.go:387] Substituting $controllermanagersvc with 'controllermanager'
I1026 12:00:43.505379   22192 util.go:387] Substituting $etcdsvc with 'etcd'
I1026 12:00:43.505384   22192 util.go:387] Substituting $flanneldsvc with 'flanneld'
I1026 12:00:43.505389   22192 util.go:387] Substituting $kubernetessvc with 'kubernetes'
I1026 12:00:43.505394   22192 util.go:387] Substituting $kubeletsvc with 'kubelet'
I1026 12:00:43.505399   22192 util.go:387] Substituting $apiserversvc with 'apiserver'
I1026 12:00:43.505415   22192 util.go:387] Substituting $kubeletkubeconfig with 'kubelet'
I1026 12:00:43.505426   22192 util.go:387] Substituting $apiserverkubeconfig with 'apiserver'
I1026 12:00:43.505431   22192 util.go:387] Substituting $schedulerkubeconfig with '/etc/kubernetes/scheduler.conf'
I1026 12:00:43.505437   22192 util.go:387] Substituting $controllermanagerkubeconfig with '/etc/kubernetes/controller-manager.conf'
I1026 12:00:43.505442   22192 util.go:387] Substituting $etcdkubeconfig with 'etcd'
I1026 12:00:43.505447   22192 util.go:387] Substituting $flanneldkubeconfig with 'flanneld'
I1026 12:00:43.505452   22192 util.go:387] Substituting $kuberneteskubeconfig with 'kubernetes'
I1026 12:00:43.505457   22192 util.go:387] Substituting $kubernetescafile with 'kubernetes'
I1026 12:00:43.505462   22192 util.go:387] Substituting $kubeletcafile with 'kubelet'
I1026 12:00:43.505467   22192 util.go:387] Substituting $apiservercafile with 'apiserver'
I1026 12:00:43.505472   22192 util.go:387] Substituting $schedulercafile with 'scheduler'
I1026 12:00:43.505477   22192 util.go:387] Substituting $controllermanagercafile with 'controllermanager'
I1026 12:00:43.505482   22192 util.go:387] Substituting $etcdcafile with 'etcd'
I1026 12:00:43.505488   22192 util.go:387] Substituting $flanneldcafile with 'flanneld'
I1026 12:00:43.505579   22192 common.go:79] Using test file: cfg/eks-1.1.0/node.yaml
I1026 12:00:43.505609   22192 util.go:79] ps - proc: "hyperkube"
I1026 12:00:43.509451   22192 util.go:83] [/bin/ps -C hyperkube -o cmd --no-headers]: exit status 1
I1026 12:00:43.509462   22192 util.go:86] ps - returning: ""
I1026 12:00:43.509482   22192 util.go:227] reFirstWord.Match()
I1026 12:00:43.509493   22192 util.go:257] executable 'hyperkube kubelet' not running
I1026 12:00:43.509498   22192 util.go:79] ps - proc: "kubelet"
I1026 12:00:43.513390   22192 util.go:86] ps - returning: "/usr/bin/kubelet --cloud-provider aws --config /etc/kubernetes/kubelet/kubelet-config.json --kubeconfig /var/lib/kubelet/kubeconfig --container-runtime docker --network-plugin cni --node-ip=10.42.11.122 --pod-infra-container-image=602401143452.dkr.ecr.us-west-2.amazonaws.com/eks/pause:3.5 --v=2 --max-pods=110\n"
I1026 12:00:43.513426   22192 util.go:227] reFirstWord.Match(/usr/bin/kubelet --cloud-provider aws --config /etc/kubernetes/kubelet/kubelet-config.json --kubeconfig /var/lib/kubelet/kubeconfig --container-runtime docker --network-plugin cni --node-ip=10.42.11.122 --pod-infra-container-image=602401143452.dkr.ecr.us-west-2.amazonaws.com/eks/pause:3.5 --v=2 --max-pods=110)
I1026 12:00:43.513451   22192 util.go:115] Component kubelet uses running binary kubelet
I1026 12:00:43.513487   22192 util.go:79] ps - proc: "kube-proxy"
I1026 12:00:43.517287   22192 util.go:86] ps - returning: "kube-proxy --v=2 --config=/var/lib/kube-proxy-config/config --hostname-override=ip-10-42-11-122.us-west-2.compute.internal\n"
I1026 12:00:43.517382   22192 util.go:227] reFirstWord.Match(kube-proxy --v=2 --config=/var/lib/kube-proxy-config/config --hostname-override=ip-10-42-11-122.us-west-2.compute.internal)
I1026 12:00:43.517392   22192 util.go:115] Component proxy uses running binary kube-proxy
I1026 12:00:43.517454   22192 util.go:200] Component kubelet uses config file '/etc/kubernetes/kubelet/kubelet-config.json'
I1026 12:00:43.517490   22192 util.go:193] Using default config file name '/etc/kubernetes/addons/kube-proxy-daemonset.yaml' for component proxy
I1026 12:00:43.517508   22192 util.go:193] Using default config file name '/etc/kubernetes/config' for component kubernetes
I1026 12:00:43.517537   22192 util.go:200] Component kubelet uses service file '/etc/systemd/system/kubelet.service'
I1026 12:00:43.517563   22192 util.go:196] Missing service file for proxy
I1026 12:00:43.517588   22192 util.go:196] Missing service file for kubernetes
I1026 12:00:43.517615   22192 util.go:200] Component kubelet uses kubeconfig file '/var/lib/kubelet/kubeconfig'
I1026 12:00:43.517638   22192 util.go:200] Component proxy uses kubeconfig file '/var/lib/kubelet/kubeconfig'
I1026 12:00:43.517657   22192 util.go:196] Missing kubeconfig file for kubernetes
I1026 12:00:43.517687   22192 util.go:200] Component kubelet uses ca file '/etc/kubernetes/pki/ca.crt'
I1026 12:00:43.517700   22192 util.go:196] Missing ca file for proxy
I1026 12:00:43.517713   22192 util.go:196] Missing ca file for kubernetes
I1026 12:00:43.517758   22192 util.go:387] Substituting $kubeletbin with 'kubelet'
I1026 12:00:43.517781   22192 util.go:387] Substituting $proxybin with 'kube-proxy'
I1026 12:00:43.517790   22192 util.go:387] Substituting $proxyconf with '/etc/kubernetes/addons/kube-proxy-daemonset.yaml'
I1026 12:00:43.517798   22192 util.go:387] Substituting $kubernetesconf with '/etc/kubernetes/config'
I1026 12:00:43.517806   22192 util.go:387] Substituting $kubeletconf with '/etc/kubernetes/kubelet/kubelet-config.json'
I1026 12:00:43.517832   22192 util.go:387] Substituting $kubeletsvc with '/etc/systemd/system/kubelet.service'
I1026 12:00:43.517850   22192 util.go:387] Substituting $proxysvc with 'proxy'
I1026 12:00:43.517857   22192 util.go:387] Substituting $kubernetessvc with 'kubernetes'
I1026 12:00:43.517863   22192 util.go:387] Substituting $kubeletkubeconfig with '/var/lib/kubelet/kubeconfig'
I1026 12:00:43.517883   22192 util.go:387] Substituting $proxykubeconfig with '/var/lib/kubelet/kubeconfig'
I1026 12:00:43.517890   22192 util.go:387] Substituting $kuberneteskubeconfig with 'kubernetes'
I1026 12:00:43.517896   22192 util.go:387] Substituting $kubeletcafile with '/etc/kubernetes/pki/ca.crt'
I1026 12:00:43.517902   22192 util.go:387] Substituting $proxycafile with 'proxy'
I1026 12:00:43.517908   22192 util.go:387] Substituting $kubernetescafile with 'kubernetes'
I1026 12:00:43.519813   22192 check.go:110] -----   Running check 3.1.1   -----
I1026 12:00:43.521089   22192 check.go:299] Command: "/bin/sh -c 'if test -e /var/lib/kubelet/kubeconfig; then stat -c permissions=%a /var/lib/kubelet/kubeconfig; fi'"
I1026 12:00:43.521102   22192 check.go:300] Output:
 "permissions=644\n"
I1026 12:00:43.521108   22192 check.go:221] Running 1 test_items
I1026 12:00:43.521146   22192 test.go:153] In flagTestItem.findValue 644
I1026 12:00:43.521164   22192 test.go:247] Flag 'permissions' exists
I1026 12:00:43.521169   22192 check.go:245] Used auditCommand
I1026 12:00:43.521183   22192 check.go:277] Returning from execute on tests: finalOutput &check.testOutput{testResult:true, flagFound:false, actualResult:"permissions=644", ExpectedResult:"permissions has permissions 644, expected 644 or more restrictive"}
I1026 12:00:43.521200   22192 check.go:184] Command: "" TestResult: true State: "PASS" 
I1026 12:00:43.521211   22192 check.go:110] -----   Running check 3.1.2   -----
I1026 12:00:43.522282   22192 check.go:299] Command: "/bin/sh -c 'if test -e /var/lib/kubelet/kubeconfig; then stat -c %U:%G /var/lib/kubelet/kubeconfig; fi'"
I1026 12:00:43.522296   22192 check.go:300] Output:
 "root:root\n"
I1026 12:00:43.522301   22192 check.go:221] Running 1 test_items
I1026 12:00:43.522353   22192 test.go:153] In flagTestItem.findValue root:root
I1026 12:00:43.522362   22192 test.go:247] Flag 'root:root' exists
I1026 12:00:43.522367   22192 check.go:245] Used auditCommand
I1026 12:00:43.522373   22192 check.go:277] Returning from execute on tests: finalOutput &check.testOutput{testResult:true, flagFound:false, actualResult:"root:root", ExpectedResult:"'root:root' is present"}
I1026 12:00:43.522387   22192 check.go:184] Command: "" TestResult: true State: "PASS" 
I1026 12:00:43.522414   22192 check.go:110] -----   Running check 3.1.3   -----
I1026 12:00:43.523368   22192 check.go:299] Command: "/bin/sh -c 'if test -e /etc/kubernetes/kubelet/kubelet-config.json; then stat -c permissions=%a /etc/kubernetes/kubelet/kubelet-config.json; fi'"
I1026 12:00:43.523381   22192 check.go:300] Output:
 "permissions=644\n"
I1026 12:00:43.523387   22192 check.go:221] Running 1 test_items
I1026 12:00:43.523434   22192 test.go:153] In flagTestItem.findValue 644
I1026 12:00:43.523453   22192 test.go:247] Flag 'permissions' exists
I1026 12:00:43.523459   22192 check.go:245] Used auditCommand
I1026 12:00:43.523465   22192 check.go:277] Returning from execute on tests: finalOutput &check.testOutput{testResult:true, flagFound:false, actualResult:"permissions=644", ExpectedResult:"permissions has permissions 644, expected 644 or more restrictive"}
I1026 12:00:43.523503   22192 check.go:184] Command: "" TestResult: true State: "PASS" 
I1026 12:00:43.523513   22192 check.go:110] -----   Running check 3.1.4   -----
I1026 12:00:43.524525   22192 check.go:299] Command: "/bin/sh -c 'if test -e /etc/kubernetes/kubelet/kubelet-config.json; then stat -c %U:%G /etc/kubernetes/kubelet/kubelet-config.json; fi'"
I1026 12:00:43.524538   22192 check.go:300] Output:
 "root:root\n"
I1026 12:00:43.524543   22192 check.go:221] Running 1 test_items
I1026 12:00:43.524725   22192 test.go:153] In flagTestItem.findValue root:root
I1026 12:00:43.524738   22192 test.go:247] Flag 'root:root' exists
I1026 12:00:43.524743   22192 check.go:245] Used auditCommand
I1026 12:00:43.524761   22192 check.go:277] Returning from execute on tests: finalOutput &check.testOutput{testResult:true, flagFound:false, actualResult:"root:root", ExpectedResult:"'root:root' is present"}
I1026 12:00:43.524774   22192 check.go:184] Command: "" TestResult: true State: "PASS" 
I1026 12:00:43.524781   22192 check.go:110] -----   Running check 3.2.1   -----
I1026 12:00:43.529197   22192 check.go:299] Command: "/bin/ps -fC kubelet"
I1026 12:00:43.529210   22192 check.go:300] Output:
 "UID        PID  PPID  C STIME TTY          TIME CMD\nroot      3276     1  0 07:56 ?        00:02:26 /usr/bin/kubelet --cloud-provider aws --config /etc/kubernetes/kubelet/kubelet-config.json --kubeconfig /var/lib/kubelet/kubeconfig --container-runtime docker --network-plugin cni --node-ip=10.42.11.122 --pod-infra-container-image=602401143452.dkr.ecr.us-west-2.amazonaws.com/eks/pause:3.5 --v=2 --max-pods=110\n"
I1026 12:00:43.529992   22192 check.go:299] Command: "/bin/cat /etc/kubernetes/kubelet/kubelet-config.json"
I1026 12:00:43.530005   22192 check.go:300] Output:
 "{\n  \"kind\": \"KubeletConfiguration\",\n  \"apiVersion\": \"kubelet.config.k8s.io/v1beta1\",\n  \"address\": \"0.0.0.0\",\n  \"authentication\": {\n    \"anonymous\": {\n      \"enabled\": false\n    },\n    \"webhook\": {\n      \"cacheTTL\": \"2m0s\",\n      \"enabled\": true\n    },\n    \"x509\": {\n      \"clientCAFile\": \"/etc/kubernetes/pki/ca.crt\"\n    }\n  },\n  \"authorization\": {\n    \"mode\": \"Webhook\",\n    \"webhook\": {\n      \"cacheAuthorizedTTL\": \"5m0s\",\n      \"cacheUnauthorizedTTL\": \"30s\"\n    }\n  },\n  \"clusterDomain\": \"cluster.local\",\n  \"hairpinMode\": \"hairpin-veth\",\n  \"readOnlyPort\": 0,\n  \"cgroupDriver\": \"cgroupfs\",\n  \"cgroupRoot\": \"/\",\n  \"featureGates\": {\n    \"RotateKubeletServerCertificate\": true\n  },\n  \"protectKernelDefaults\": true,\n  \"serializeImagePulls\": false,\n  \"serverTLSBootstrap\": true,\n  \"tlsCipherSuites\": [\n    \"TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256\",\n    \"TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256\",\n    \"TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305\",\n    \"TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384\",\n    \"TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305\",\n    \"TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384\",\n    \"TLS_RSA_WITH_AES_256_GCM_SHA384\",\n    \"TLS_RSA_WITH_AES_128_GCM_SHA256\"\n  ],\n  \"clusterDNS\": [\n    \"172.20.0.10\"\n  ],\n  \"evictionHard\": {\n    \"memory.available\": \"100Mi\",\n    \"nodefs.available\": \"10%\",\n    \"nodefs.inodesFree\": \"5%\"\n  },\n  \"kubeReserved\": {\n    \"cpu\": \"70m\",\n    \"ephemeral-storage\": \"1Gi\",\n    \"memory\": \"574Mi\"\n  }\n}\n"

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
