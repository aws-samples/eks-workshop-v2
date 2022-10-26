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
I1026 11:36:45.656162    7093 util.go:486] Checking for oc
I1026 11:36:45.656259    7093 util.go:515] Can't find oc command: exec: "oc": executable file not found in $PATH
I1026 11:36:45.656283    7093 kubernetes_version.go:36] Try to get version from Rest API
I1026 11:36:45.656325    7093 kubernetes_version.go:161] Loading CA certificate
I1026 11:36:45.656356    7093 kubernetes_version.go:115] getWebData srvURL: https://kubernetes.default.svc/version
I1026 11:36:45.690377    7093 kubernetes_version.go:100] vd: {
  "major": "1",
  "minor": "23+",
  "gitVersion": "v1.23.10-eks-15b7512",
  "gitCommit": "cd6399691d9b1fed9ec20c9c5e82f5993c3f42cb",
  "gitTreeState": "clean",
  "buildDate": "2022-08-31T19:17:01Z",
  "goVersion": "go1.17.13",
  "compiler": "gc",
  "platform": "linux/amd64"
}
I1026 11:36:45.690455    7093 kubernetes_version.go:105] vrObj: &cmd.VersionResponse{Major:"1", Minor:"23+", GitVersion:"v1.23.10-eks-15b7512", GitCommit:"cd6399691d9b1fed9ec20c9c5e82f5993c3f42cb", GitTreeState:"clean", BuildDate:"2022-08-31T19:17:01Z", GoVersion:"go1.17.13", Compiler:"gc", Platform:"linux/amd64"}
I1026 11:36:45.690479    7093 util.go:293] Kubernetes REST API Reported version: &{1 23+  v1.23.10-eks-15b7512}
I1026 11:36:45.690567    7093 common.go:350] Kubernetes version: "" to Benchmark version: "eks-1.1.0"
I1026 11:36:45.690577    7093 root.go:76] Running checks for benchmark eks-1.1.0
I1026 11:36:45.690582    7093 common.go:365] Checking if the current node is running master components
I1026 11:36:45.690624    7093 util.go:79] ps - proc: "kube-apiserver"
I1026 11:36:45.695320    7093 util.go:83] [/bin/ps -C kube-apiserver -o cmd --no-headers]: exit status 1
I1026 11:36:45.695334    7093 util.go:86] ps - returning: ""
I1026 11:36:45.695357    7093 util.go:227] reFirstWord.Match()
I1026 11:36:45.695362    7093 util.go:257] executable 'kube-apiserver' not running
I1026 11:36:45.695368    7093 util.go:79] ps - proc: "hyperkube"
I1026 11:36:45.699394    7093 util.go:83] [/bin/ps -C hyperkube -o cmd --no-headers]: exit status 1
I1026 11:36:45.699408    7093 util.go:86] ps - returning: ""
I1026 11:36:45.699432    7093 util.go:227] reFirstWord.Match()
I1026 11:36:45.699438    7093 util.go:257] executable 'hyperkube apiserver' not running
I1026 11:36:45.699443    7093 util.go:79] ps - proc: "hyperkube"
I1026 11:36:45.703278    7093 util.go:83] [/bin/ps -C hyperkube -o cmd --no-headers]: exit status 1
I1026 11:36:45.703291    7093 util.go:86] ps - returning: ""
I1026 11:36:45.703322    7093 util.go:227] reFirstWord.Match()
I1026 11:36:45.703328    7093 util.go:257] executable 'hyperkube kube-apiserver' not running
I1026 11:36:45.703332    7093 util.go:79] ps - proc: "apiserver"
I1026 11:36:45.707102    7093 util.go:83] [/bin/ps -C apiserver -o cmd --no-headers]: exit status 1
I1026 11:36:45.707115    7093 util.go:86] ps - returning: ""
I1026 11:36:45.707135    7093 util.go:227] reFirstWord.Match()
I1026 11:36:45.707140    7093 util.go:257] executable 'apiserver' not running
I1026 11:36:45.707145    7093 util.go:79] ps - proc: "openshift"
I1026 11:36:45.711026    7093 util.go:83] [/bin/ps -C openshift -o cmd --no-headers]: exit status 1
I1026 11:36:45.711039    7093 util.go:86] ps - returning: ""
I1026 11:36:45.711073    7093 util.go:227] reFirstWord.Match()
I1026 11:36:45.711078    7093 util.go:257] executable 'openshift start master api' not running
I1026 11:36:45.711084    7093 util.go:79] ps - proc: "hypershift"
I1026 11:36:45.715004    7093 util.go:83] [/bin/ps -C hypershift -o cmd --no-headers]: exit status 1
I1026 11:36:45.715016    7093 util.go:86] ps - returning: ""
I1026 11:36:45.715061    7093 util.go:227] reFirstWord.Match()
I1026 11:36:45.715067    7093 util.go:257] executable 'hypershift openshift-kube-apiserver' not running
I1026 11:36:45.715094    7093 util.go:106] 
Unable to detect running programs for component "apiserver"
The following "master node" programs have been searched, but none of them have been found:
        - kube-apiserver
        - hyperkube apiserver
        - hyperkube kube-apiserver
        - apiserver
        - openshift start master api
        - hypershift openshift-kube-apiserver


These program names are provided in the config.yaml, section 'master.apiserver.bins'
I1026 11:36:45.715106    7093 common.go:374] Failed to find master binaries: unable to detect running programs for component "apiserver"
I1026 11:36:45.715115    7093 root.go:93] == Skipping master checks ==
I1026 11:36:45.715169    7093 root.go:106] == Skipping etcd checks ==
I1026 11:36:45.715176    7093 root.go:109] == Running node checks ==
I1026 11:36:45.715182    7093 util.go:126] Looking for config specific CIS version "eks-1.1.0"
I1026 11:36:45.715190    7093 util.go:130] Looking for file: cfg/eks-1.1.0/node.yaml
I1026 11:36:45.715314    7093 common.go:273] Using config file: cfg/eks-1.1.0/config.yaml
I1026 11:36:45.715357    7093 common.go:79] Using test file: cfg/eks-1.1.0/node.yaml
I1026 11:36:45.715400    7093 util.go:79] ps - proc: "hyperkube"
I1026 11:36:45.719656    7093 util.go:83] [/bin/ps -C hyperkube -o cmd --no-headers]: exit status 1
I1026 11:36:45.719673    7093 util.go:86] ps - returning: ""
I1026 11:36:45.719708    7093 util.go:227] reFirstWord.Match()
I1026 11:36:45.719714    7093 util.go:257] executable 'hyperkube kubelet' not running
I1026 11:36:45.719719    7093 util.go:79] ps - proc: "kubelet"
I1026 11:36:45.724038    7093 util.go:86] ps - returning: "/usr/bin/kubelet --cloud-provider aws --config /etc/kubernetes/kubelet/kubelet-config.json --kubeconfig /var/lib/kubelet/kubeconfig --container-runtime docker --network-plugin cni --node-ip=10.42.11.122 --pod-infra-container-image=602401143452.dkr.ecr.us-west-2.amazonaws.com/eks/pause:3.5 --v=2 --max-pods=110\n"
I1026 11:36:45.724149    7093 util.go:227] reFirstWord.Match(/usr/bin/kubelet --cloud-provider aws --config /etc/kubernetes/kubelet/kubelet-config.json --kubeconfig /var/lib/kubelet/kubeconfig --container-runtime docker --network-plugin cni --node-ip=10.42.11.122 --pod-infra-container-image=602401143452.dkr.ecr.us-west-2.amazonaws.com/eks/pause:3.5 --v=2 --max-pods=110)
I1026 11:36:45.724216    7093 util.go:115] Component kubelet uses running binary kubelet
I1026 11:36:45.724289    7093 util.go:79] ps - proc: "kube-proxy"
I1026 11:36:45.728338    7093 util.go:86] ps - returning: "kube-proxy --v=2 --config=/var/lib/kube-proxy-config/config --hostname-override=ip-10-42-11-122.us-west-2.compute.internal\n"
I1026 11:36:45.728370    7093 util.go:227] reFirstWord.Match(kube-proxy --v=2 --config=/var/lib/kube-proxy-config/config --hostname-override=ip-10-42-11-122.us-west-2.compute.internal)
I1026 11:36:45.728380    7093 util.go:115] Component proxy uses running binary kube-proxy
I1026 11:36:45.728457    7093 util.go:200] Component kubelet uses config file '/etc/kubernetes/kubelet/kubelet-config.json'
I1026 11:36:45.728506    7093 util.go:193] Using default config file name '/etc/kubernetes/addons/kube-proxy-daemonset.yaml' for component proxy
I1026 11:36:45.728530    7093 util.go:193] Using default config file name '/etc/kubernetes/config' for component kubernetes
I1026 11:36:45.728561    7093 util.go:200] Component kubelet uses service file '/etc/systemd/system/kubelet.service'
I1026 11:36:45.728608    7093 util.go:196] Missing service file for proxy
I1026 11:36:45.728621    7093 util.go:196] Missing service file for kubernetes
I1026 11:36:45.728644    7093 util.go:200] Component kubelet uses kubeconfig file '/var/lib/kubelet/kubeconfig'
I1026 11:36:45.728677    7093 util.go:200] Component proxy uses kubeconfig file '/var/lib/kubelet/kubeconfig'
I1026 11:36:45.728693    7093 util.go:196] Missing kubeconfig file for kubernetes
I1026 11:36:45.728711    7093 util.go:200] Component kubelet uses ca file '/etc/kubernetes/pki/ca.crt'
I1026 11:36:45.728726    7093 util.go:196] Missing ca file for proxy
I1026 11:36:45.728744    7093 util.go:196] Missing ca file for kubernetes
I1026 11:36:45.728764    7093 util.go:387] Substituting $kubeletbin with 'kubelet'
I1026 11:36:45.728785    7093 util.go:387] Substituting $proxybin with 'kube-proxy'
I1026 11:36:45.728793    7093 util.go:387] Substituting $proxyconf with '/etc/kubernetes/addons/kube-proxy-daemonset.yaml'
I1026 11:36:45.728800    7093 util.go:387] Substituting $kubernetesconf with '/etc/kubernetes/config'
I1026 11:36:45.728810    7093 util.go:387] Substituting $kubeletconf with '/etc/kubernetes/kubelet/kubelet-config.json'
I1026 11:36:45.728838    7093 util.go:387] Substituting $kubeletsvc with '/etc/systemd/system/kubelet.service'
I1026 11:36:45.728860    7093 util.go:387] Substituting $proxysvc with 'proxy'
I1026 11:36:45.728867    7093 util.go:387] Substituting $kubernetessvc with 'kubernetes'
I1026 11:36:45.728874    7093 util.go:387] Substituting $kubeletkubeconfig with '/var/lib/kubelet/kubeconfig'
I1026 11:36:45.728896    7093 util.go:387] Substituting $proxykubeconfig with '/var/lib/kubelet/kubeconfig'
I1026 11:36:45.728902    7093 util.go:387] Substituting $kuberneteskubeconfig with 'kubernetes'
I1026 11:36:45.728908    7093 util.go:387] Substituting $kubeletcafile with '/etc/kubernetes/pki/ca.crt'
I1026 11:36:45.728914    7093 util.go:387] Substituting $proxycafile with 'proxy'
I1026 11:36:45.728920    7093 util.go:387] Substituting $kubernetescafile with 'kubernetes'
I1026 11:36:45.729750    7093 check.go:110] -----   Running check 3.1.1   -----
I1026 11:36:45.730826    7093 check.go:299] Command: "/bin/sh -c 'if test -e /var/lib/kubelet/kubeconfig; then stat -c permissions=%a /var/lib/kubelet/kubeconfig; fi'"
I1026 11:36:45.730839    7093 check.go:300] Output:
 "permissions=644\n"
I1026 11:36:45.730845    7093 check.go:221] Running 1 test_items
I1026 11:36:45.730888    7093 test.go:153] In flagTestItem.findValue 644
I1026 11:36:45.730899    7093 test.go:247] Flag 'permissions' exists
I1026 11:36:45.730903    7093 check.go:245] Used auditCommand
I1026 11:36:45.730917    7093 check.go:277] Returning from execute on tests: finalOutput &check.testOutput{testResult:true, flagFound:false, actualResult:"permissions=644", ExpectedResult:"permissions has permissions 644, expected 644 or more restrictive"}
I1026 11:36:45.730935    7093 check.go:184] Command: "" TestResult: true State: "PASS" 
I1026 11:36:45.730950    7093 check.go:110] -----   Running check 3.1.2   -----
I1026 11:36:45.731975    7093 check.go:299] Command: "/bin/sh -c 'if test -e /var/lib/kubelet/kubeconfig; then stat -c %U:%G /var/lib/kubelet/kubeconfig; fi'"
I1026 11:36:45.731988    7093 check.go:300] Output:
 "root:root\n"
I1026 11:36:45.731993    7093 check.go:221] Running 1 test_items
I1026 11:36:45.732030    7093 test.go:153] In flagTestItem.findValue root:root
I1026 11:36:45.732039    7093 test.go:247] Flag 'root:root' exists
I1026 11:36:45.732044    7093 check.go:245] Used auditCommand
I1026 11:36:45.732050    7093 check.go:277] Returning from execute on tests: finalOutput &check.testOutput{testResult:true, flagFound:false, actualResult:"root:root", ExpectedResult:"'root:root' is present"}
I1026 11:36:45.732063    7093 check.go:184] Command: "" TestResult: true State: "PASS" 
I1026 11:36:45.732072    7093 check.go:110] -----   Running check 3.1.3   -----
I1026 11:36:45.733096    7093 check.go:299] Command: "/bin/sh -c 'if test -e /etc/kubernetes/kubelet/kubelet-config.json; then stat -c permissions=%a /etc/kubernetes/kubelet/kubelet-config.json; fi'"
I1026 11:36:45.733109    7093 check.go:300] Output:
 "permissions=644\n"
I1026 11:36:45.733114    7093 check.go:221] Running 1 test_items
I1026 11:36:45.733175    7093 test.go:153] In flagTestItem.findValue 644
I1026 11:36:45.733185    7093 test.go:247] Flag 'permissions' exists
I1026 11:36:45.733190    7093 check.go:245] Used auditCommand
I1026 11:36:45.733196    7093 check.go:277] Returning from execute on tests: finalOutput &check.testOutput{testResult:true, flagFound:false, actualResult:"permissions=644", ExpectedResult:"permissions has permissions 644, expected 644 or more restrictive"}
I1026 11:36:45.733267    7093 check.go:184] Command: "" TestResult: true State: "PASS" 
I1026 11:36:45.733275    7093 check.go:110] -----   Running check 3.1.4   -----
I1026 11:36:45.734285    7093 check.go:299] Command: "/bin/sh -c 'if test -e /etc/kubernetes/kubelet/kubelet-config.json; then stat -c %U:%G /etc/kubernetes/kubelet/kubelet-config.json; fi'"
I1026 11:36:45.734299    7093 check.go:300] Output:
 "root:root\n"
I1026 11:36:45.734304    7093 check.go:221] Running 1 test_items
I1026 11:36:45.734334    7093 test.go:153] In flagTestItem.findValue root:root
I1026 11:36:45.734342    7093 test.go:247] Flag 'root:root' exists
I1026 11:36:45.734346    7093 check.go:245] Used auditCommand
I1026 11:36:45.734352    7093 check.go:277] Returning from execute on tests: finalOutput &check.testOutput{testResult:true, flagFound:false, actualResult:"root:root", ExpectedResult:"'root:root' is present"}
I1026 11:36:45.734364    7093 check.go:184] Command: "" TestResult: true State: "PASS" 
I1026 11:36:45.734370    7093 check.go:110] -----   Running check 3.2.1   -----
I1026 11:36:45.738878    7093 check.go:299] Command: "/bin/ps -fC kubelet"
I1026 11:36:45.738891    7093 check.go:300] Output:
 "UID        PID  PPID  C STIME TTY          TIME CMD\nroot      3276     1  0 07:56 ?        00:02:11 /usr/bin/kubelet --cloud-provider aws --config /etc/kubernetes/kubelet/kubelet-config.json --kubeconfig /var/lib/kubelet/kubeconfig --container-runtime docker --network-plugin cni --node-ip=10.42.11.122 --pod-infra-container-image=602401143452.dkr.ecr.us-west-2.amazonaws.com/eks/pause:3.5 --v=2 --max-pods=110\n"
I1026 11:36:45.739686    7093 check.go:299] Command: "/bin/cat /etc/kubernetes/kubelet/kubelet-config.json"
I1026 11:36:45.739698    7093 check.go:300] Output:
 "{\n  \"kind\": \"KubeletConfiguration\",\n  \"apiVersion\": \"kubelet.config.k8s.io/v1beta1\",\n  \"address\": \"0.0.0.0\",\n  \"authentication\": {\n    \"anonymous\": {\n      \"enabled\": false\n    },\n    \"webhook\": {\n      \"cacheTTL\": \"2m0s\",\n      \"enabled\": true\n    },\n    \"x509\": {\n      \"clientCAFile\": \"/etc/kubernetes/pki/ca.crt\"\n    }\n  },\n  \"authorization\": {\n    \"mode\": \"Webhook\",\n    \"webhook\": {\n      \"cacheAuthorizedTTL\": \"5m0s\",\n      \"cacheUnauthorizedTTL\": \"30s\"\n    }\n  },\n  \"clusterDomain\": \"cluster.local\",\n  \"hairpinMode\": \"hairpin-veth\",\n  \"readOnlyPort\": 0,\n  \"cgroupDriver\": \"cgroupfs\",\n  \"cgroupRoot\": \"/\",\n  \"featureGates\": {\n    \"RotateKubeletServerCertificate\": true\n  },\n  \"protectKernelDefaults\": true,\n  \"serializeImagePulls\": false,\n  \"serverTLSBootstrap\": true,\n  \"tlsCipherSuites\": [\n    \"TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256\",\n    \"TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256\",\n    \"TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305\",\n    \"TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384\",\n    \"TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305\",\n    \"TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384\",\n    \"TLS_RSA_WITH_AES_256_GCM_SHA384\",\n    \"TLS_RSA_WITH_AES_128_GCM_SHA256\"\n  ],\n  \"clusterDNS\": [\n    \"172.20.0.10\"\n  ],\n  \"evictionHard\": {\n    \"memory.available\": \"100Mi\",\n    \"nodefs.available\": \"10%\",\n    \"nodefs.inodesFree\": \"5%\"\n  },\n  \"kubeReserved\": {\n    \"cpu\": \"70m\",\n    \"ephemeral-storage\": \"1Gi\",\n    \"memory\": \"574Mi\"\n  }\n}\n"
I1026 11:36:45.739749    7093 check.go:221] Running 1 test_items
I1026 11:36:45.739756    7093 test.go:153] In flagTestItem.findValue 
I1026 11:36:45.739763    7093 test.go:247] Flag '--anonymous-auth' does not exist
I1026 11:36:45.739839    7093 test.go:171] In pathTestItem.findValue false
I1026 11:36:45.739847    7093 test.go:249] Path '{.authentication.anonymous.enabled}' exists
I1026 11:36:45.739852    7093 check.go:245] Used auditConfig
I1026 11:36:45.739858    7093 check.go:277] Returning from execute on tests: finalOutput &check.testOutput{testResult:true, flagFound:false, actualResult:"{\n  \"kind\": \"KubeletConfiguration\",\n  \"apiVersion\": \"kubelet.config.k8s.io/v1beta1\",\n  \"address\": \"0.0.0.0\",\n  \"authentication\": {\n    \"anonymous\": {\n      \"enabled\": false\n    },\n    \"webhook\": {\n      \"cacheTTL\": \"2m0s\",\n      \"enabled\": true\n    },\n    \"x509\": {\n      \"clientCAFile\": \"/etc/kubernetes/pki/ca.crt\"\n    }\n  },\n  \"authorization\": {\n    \"mode\": \"Webhook\",\n    \"webhook\": {\n      \"cacheAuthorizedTTL\": \"5m0s\",\n      \"cacheUnauthorizedTTL\": \"30s\"\n    }\n  },\n  \"clusterDomain\": \"cluster.local\",\n  \"hairpinMode\": \"hairpin-veth\",\n  \"readOnlyPort\": 0,\n  \"cgroupDriver\": \"cgroupfs\",\n  \"cgroupRoot\": \"/\",\n  \"featureGates\": {\n    \"RotateKubeletServerCertificate\": true\n  },\n  \"protectKernelDefaults\": true,\n  \"serializeImagePulls\": false,\n  \"serverTLSBootstrap\": true,\n  \"tlsCipherSuites\": [\n    \"TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256\",\n    \"TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256\",\n    \"TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305\",\n    \"TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384\",\n    \"TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305\",\n    \"TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384\",\n    \"TLS_RSA_WITH_AES_256_GCM_SHA384\",\n    \"TLS_RSA_WITH_AES_128_GCM_SHA256\"\n  ],\n  \"clusterDNS\": [\n    \"172.20.0.10\"\n  ],\n  \"evictionHard\": {\n    \"memory.available\": \"100Mi\",\n    \"nodefs.available\": \"10%\",\n    \"nodefs.inodesFree\": \"5%\"\n  },\n  \"kubeReserved\": {\n    \"cpu\": \"70m\",\n    \"ephemeral-storage\": \"1Gi\",\n    \"memory\": \"574Mi\"\n  }\n}", ExpectedResult:"'{.authentication.anonymous.enabled}' is equal to 'false'"}
I1026 11:36:45.739910    7093 check.go:184] Command: "/bin/cat /etc/kubernetes/kubelet/kubelet-config.json" TestResult: true State: "PASS" 
I1026 11:36:45.739919    7093 check.go:110] -----   Running check 3.2.2   -----
I1026 11:36:45.744468    7093 check.go:299] Command: "/bin/ps -fC kubelet"
I1026 11:36:45.744480    7093 check.go:300] Output:
 "UID        PID  PPID  C STIME TTY          TIME CMD\nroot      3276     1  0 07:56 ?        00:02:11 /usr/bin/kubelet --cloud-provider aws --config /etc/kubernetes/kubelet/kubelet-config.json --kubeconfig /var/lib/kubelet/kubeconfig --container-runtime docker --network-plugin cni --node-ip=10.42.11.122 --pod-infra-container-image=602401143452.dkr.ecr.us-west-2.amazonaws.com/eks/pause:3.5 --v=2 --max-pods=110\n"
I1026 11:36:45.745320    7093 check.go:299] Command: "/bin/cat /etc/kubernetes/kubelet/kubelet-config.json"
I1026 11:36:45.745334    7093 check.go:300] Output:
 "{\n  \"kind\": \"KubeletConfiguration\",\n  \"apiVersion\": \"kubelet.config.k8s.io/v1beta1\",\n  \"address\": \"0.0.0.0\",\n  \"authentication\": {\n    \"anonymous\": {\n      \"enabled\": false\n    },\n    \"webhook\": {\n      \"cacheTTL\": \"2m0s\",\n      \"enabled\": true\n    },\n    \"x509\": {\n      \"clientCAFile\": \"/etc/kubernetes/pki/ca.crt\"\n    }\n  },\n  \"authorization\": {\n    \"mode\": \"Webhook\",\n    \"webhook\": {\n      \"cacheAuthorizedTTL\": \"5m0s\",\n      \"cacheUnauthorizedTTL\": \"30s\"\n    }\n  },\n  \"clusterDomain\": \"cluster.local\",\n  \"hairpinMode\": \"hairpin-veth\",\n  \"readOnlyPort\": 0,\n  \"cgroupDriver\": \"cgroupfs\",\n  \"cgroupRoot\": \"/\",\n  \"featureGates\": {\n    \"RotateKubeletServerCertificate\": true\n  },\n  \"protectKernelDefaults\": true,\n  \"serializeImagePulls\": false,\n  \"serverTLSBootstrap\": true,\n  \"tlsCipherSuites\": [\n    \"TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256\",\n    \"TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256\",\n    \"TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305\",\n    \"TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384\",\n    \"TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305\",\n    \"TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384\",\n    \"TLS_RSA_WITH_AES_256_GCM_SHA384\",\n    \"TLS_RSA_WITH_AES_128_GCM_SHA256\"\n  ],\n  \"clusterDNS\": [\n    \"172.20.0.10\"\n  ],\n  \"evictionHard\": {\n    \"memory.available\": \"100Mi\",\n    \"nodefs.available\": \"10%\",\n    \"nodefs.inodesFree\": \"5%\"\n  },\n  \"kubeReserved\": {\n    \"cpu\": \"70m\",\n    \"ephemeral-storage\": \"1Gi\",\n    \"memory\": \"574Mi\"\n  }\n}\n"
I1026 11:36:45.745386    7093 check.go:221] Running 1 test_items
I1026 11:36:45.745395    7093 test.go:153] In flagTestItem.findValue 
I1026 11:36:45.745402    7093 test.go:247] Flag '--authorization-mode' does not exist
I1026 11:36:45.745548    7093 test.go:171] In pathTestItem.findValue Webhook
I1026 11:36:45.745560    7093 test.go:249] Path '{.authorization.mode}' exists
I1026 11:36:45.745565    7093 check.go:245] Used auditConfig
I1026 11:36:45.745572    7093 check.go:277] Returning from execute on tests: finalOutput &check.testOutput{testResult:true, flagFound:false, actualResult:"{\n  \"kind\": \"KubeletConfiguration\",\n  \"apiVersion\": \"kubelet.config.k8s.io/v1beta1\",\n  \"address\": \"0.0.0.0\",\n  \"authentication\": {\n    \"anonymous\": {\n      \"enabled\": false\n    },\n    \"webhook\": {\n      \"cacheTTL\": \"2m0s\",\n      \"enabled\": true\n    },\n    \"x509\": {\n      \"clientCAFile\": \"/etc/kubernetes/pki/ca.crt\"\n    }\n  },\n  \"authorization\": {\n    \"mode\": \"Webhook\",\n    \"webhook\": {\n      \"cacheAuthorizedTTL\": \"5m0s\",\n      \"cacheUnauthorizedTTL\": \"30s\"\n    }\n  },\n  \"clusterDomain\": \"cluster.local\",\n  \"hairpinMode\": \"hairpin-veth\",\n  \"readOnlyPort\": 0,\n  \"cgroupDriver\": \"cgroupfs\",\n  \"cgroupRoot\": \"/\",\n  \"featureGates\": {\n    \"RotateKubeletServerCertificate\": true\n  },\n  \"protectKernelDefaults\": true,\n  \"serializeImagePulls\": false,\n  \"serverTLSBootstrap\": true,\n  \"tlsCipherSuites\": [\n    \"TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256\",\n    \"TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256\",\n    \"TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305\",\n    \"TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384\",\n    \"TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305\",\n    \"TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384\",\n    \"TLS_RSA_WITH_AES_256_GCM_SHA384\",\n    \"TLS_RSA_WITH_AES_128_GCM_SHA256\"\n  ],\n  \"clusterDNS\": [\n    \"172.20.0.10\"\n  ],\n  \"evictionHard\": {\n    \"memory.available\": \"100Mi\",\n    \"nodefs.available\": \"10%\",\n    \"nodefs.inodesFree\": \"5%\"\n  },\n  \"kubeReserved\": {\n    \"cpu\": \"70m\",\n    \"ephemeral-storage\": \"1Gi\",\n    \"memory\": \"574Mi\"\n  }\n}", ExpectedResult:"'{.authorization.mode}' does not have 'AlwaysAllow'"}
I1026 11:36:45.745627    7093 check.go:184] Command: "/bin/cat /etc/kubernetes/kubelet/kubelet-config.json" TestResult: true State: "PASS" 
I1026 11:36:45.745678    7093 check.go:110] -----   Running check 3.2.3   -----
I1026 11:36:45.750152    7093 check.go:299] Command: "/bin/ps -fC kubelet"
I1026 11:36:45.750164    7093 check.go:300] Output:
 "UID        PID  PPID  C STIME TTY          TIME CMD\nroot      3276     1  0 07:56 ?        00:02:11 /usr/bin/kubelet --cloud-provider aws --config /etc/kubernetes/kubelet/kubelet-config.json --kubeconfig /var/lib/kubelet/kubeconfig --container-runtime docker --network-plugin cni --node-ip=10.42.11.122 --pod-infra-container-image=602401143452.dkr.ecr.us-west-2.amazonaws.com/eks/pause:3.5 --v=2 --max-pods=110\n"
I1026 11:36:45.750959    7093 check.go:299] Command: "/bin/cat /etc/kubernetes/kubelet/kubelet-config.json"
I1026 11:36:45.750972    7093 check.go:300] Output:
 "{\n  \"kind\": \"KubeletConfiguration\",\n  \"apiVersion\": \"kubelet.config.k8s.io/v1beta1\",\n  \"address\": \"0.0.0.0\",\n  \"authentication\": {\n    \"anonymous\": {\n      \"enabled\": false\n    },\n    \"webhook\": {\n      \"cacheTTL\": \"2m0s\",\n      \"enabled\": true\n    },\n    \"x509\": {\n      \"clientCAFile\": \"/etc/kubernetes/pki/ca.crt\"\n    }\n  },\n  \"authorization\": {\n    \"mode\": \"Webhook\",\n    \"webhook\": {\n      \"cacheAuthorizedTTL\": \"5m0s\",\n      \"cacheUnauthorizedTTL\": \"30s\"\n    }\n  },\n  \"clusterDomain\": \"cluster.local\",\n  \"hairpinMode\": \"hairpin-veth\",\n  \"readOnlyPort\": 0,\n  \"cgroupDriver\": \"cgroupfs\",\n  \"cgroupRoot\": \"/\",\n  \"featureGates\": {\n    \"RotateKubeletServerCertificate\": true\n  },\n  \"protectKernelDefaults\": true,\n  \"serializeImagePulls\": false,\n  \"serverTLSBootstrap\": true,\n  \"tlsCipherSuites\": [\n    \"TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256\",\n    \"TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256\",\n    \"TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305\",\n    \"TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384\",\n    \"TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305\",\n    \"TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384\",\n    \"TLS_RSA_WITH_AES_256_GCM_SHA384\",\n    \"TLS_RSA_WITH_AES_128_GCM_SHA256\"\n  ],\n  \"clusterDNS\": [\n    \"172.20.0.10\"\n  ],\n  \"evictionHard\": {\n    \"memory.available\": \"100Mi\",\n    \"nodefs.available\": \"10%\",\n    \"nodefs.inodesFree\": \"5%\"\n  },\n  \"kubeReserved\": {\n    \"cpu\": \"70m\",\n    \"ephemeral-storage\": \"1Gi\",\n    \"memory\": \"574Mi\"\n  }\n}\n"
I1026 11:36:45.751011    7093 check.go:221] Running 1 test_items
I1026 11:36:45.751019    7093 test.go:153] In flagTestItem.findValue 
I1026 11:36:45.751026    7093 test.go:247] Flag '--client-ca-file' does not exist
I1026 11:36:45.751098    7093 test.go:171] In pathTestItem.findValue /etc/kubernetes/pki/ca.crt
I1026 11:36:45.751106    7093 test.go:249] Path '{.authentication.x509.clientCAFile}' exists
I1026 11:36:45.751111    7093 check.go:245] Used auditConfig
I1026 11:36:45.751118    7093 check.go:277] Returning from execute on tests: finalOutput &check.testOutput{testResult:true, flagFound:false, actualResult:"{\n  \"kind\": \"KubeletConfiguration\",\n  \"apiVersion\": \"kubelet.config.k8s.io/v1beta1\",\n  \"address\": \"0.0.0.0\",\n  \"authentication\": {\n    \"anonymous\": {\n      \"enabled\": false\n    },\n    \"webhook\": {\n      \"cacheTTL\": \"2m0s\",\n      \"enabled\": true\n    },\n    \"x509\": {\n      \"clientCAFile\": \"/etc/kubernetes/pki/ca.crt\"\n    }\n  },\n  \"authorization\": {\n    \"mode\": \"Webhook\",\n    \"webhook\": {\n      \"cacheAuthorizedTTL\": \"5m0s\",\n      \"cacheUnauthorizedTTL\": \"30s\"\n    }\n  },\n  \"clusterDomain\": \"cluster.local\",\n  \"hairpinMode\": \"hairpin-veth\",\n  \"readOnlyPort\": 0,\n  \"cgroupDriver\": \"cgroupfs\",\n  \"cgroupRoot\": \"/\",\n  \"featureGates\": {\n    \"RotateKubeletServerCertificate\": true\n  },\n  \"protectKernelDefaults\": true,\n  \"serializeImagePulls\": false,\n  \"serverTLSBootstrap\": true,\n  \"tlsCipherSuites\": [\n    \"TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256\",\n    \"TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256\",\n    \"TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305\",\n    \"TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384\",\n    \"TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305\",\n    \"TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384\",\n    \"TLS_RSA_WITH_AES_256_GCM_SHA384\",\n    \"TLS_RSA_WITH_AES_128_GCM_SHA256\"\n  ],\n  \"clusterDNS\": [\n    \"172.20.0.10\"\n  ],\n  \"evictionHard\": {\n    \"memory.available\": \"100Mi\",\n    \"nodefs.available\": \"10%\",\n    \"nodefs.inodesFree\": \"5%\"\n  },\n  \"kubeReserved\": {\n    \"cpu\": \"70m\",\n    \"ephemeral-storage\": \"1Gi\",\n    \"memory\": \"574Mi\"\n  }\n}", ExpectedResult:"'{.authentication.x509.clientCAFile}' is present"}
I1026 11:36:45.751166    7093 check.go:184] Command: "/bin/cat /etc/kubernetes/kubelet/kubelet-config.json" TestResult: true State: "PASS" 
I1026 11:36:45.751175    7093 check.go:110] -----   Running check 3.2.4   -----
I1026 11:36:45.755631    7093 check.go:299] Command: "/bin/ps -fC kubelet"
I1026 11:36:45.755645    7093 check.go:300] Output:
 "UID        PID  PPID  C STIME TTY          TIME CMD\nroot      3276     1  0 07:56 ?        00:02:11 /usr/bin/kubelet --cloud-provider aws --config /etc/kubernetes/kubelet/kubelet-config.json --kubeconfig /var/lib/kubelet/kubeconfig --container-runtime docker --network-plugin cni --node-ip=10.42.11.122 --pod-infra-container-image=602401143452.dkr.ecr.us-west-2.amazonaws.com/eks/pause:3.5 --v=2 --max-pods=110\n"
I1026 11:36:45.756434    7093 check.go:299] Command: "/bin/cat /etc/kubernetes/kubelet/kubelet-config.json"
I1026 11:36:45.756447    7093 check.go:300] Output:
 "{\n  \"kind\": \"KubeletConfiguration\",\n  \"apiVersion\": \"kubelet.config.k8s.io/v1beta1\",\n  \"address\": \"0.0.0.0\",\n  \"authentication\": {\n    \"anonymous\": {\n      \"enabled\": false\n    },\n    \"webhook\": {\n      \"cacheTTL\": \"2m0s\",\n      \"enabled\": true\n    },\n    \"x509\": {\n      \"clientCAFile\": \"/etc/kubernetes/pki/ca.crt\"\n    }\n  },\n  \"authorization\": {\n    \"mode\": \"Webhook\",\n    \"webhook\": {\n      \"cacheAuthorizedTTL\": \"5m0s\",\n      \"cacheUnauthorizedTTL\": \"30s\"\n    }\n  },\n  \"clusterDomain\": \"cluster.local\",\n  \"hairpinMode\": \"hairpin-veth\",\n  \"readOnlyPort\": 0,\n  \"cgroupDriver\": \"cgroupfs\",\n  \"cgroupRoot\": \"/\",\n  \"featureGates\": {\n    \"RotateKubeletServerCertificate\": true\n  },\n  \"protectKernelDefaults\": true,\n  \"serializeImagePulls\": false,\n  \"serverTLSBootstrap\": true,\n  \"tlsCipherSuites\": [\n    \"TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256\",\n    \"TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256\",\n    \"TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305\",\n    \"TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384\",\n    \"TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305\",\n    \"TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384\",\n    \"TLS_RSA_WITH_AES_256_GCM_SHA384\",\n    \"TLS_RSA_WITH_AES_128_GCM_SHA256\"\n  ],\n  \"clusterDNS\": [\n    \"172.20.0.10\"\n  ],\n  \"evictionHard\": {\n    \"memory.available\": \"100Mi\",\n    \"nodefs.available\": \"10%\",\n    \"nodefs.inodesFree\": \"5%\"\n  },\n  \"kubeReserved\": {\n    \"cpu\": \"70m\",\n    \"ephemeral-storage\": \"1Gi\",\n    \"memory\": \"574Mi\"\n  }\n}\n"
I1026 11:36:45.756499    7093 check.go:221] Running 1 test_items
I1026 11:36:45.756507    7093 test.go:153] In flagTestItem.findValue 
I1026 11:36:45.756514    7093 test.go:247] Flag '--read-only-port' does not exist
I1026 11:36:45.756726    7093 test.go:171] In pathTestItem.findValue 0
I1026 11:36:45.756740    7093 test.go:249] Path '{.readOnlyPort}' exists
I1026 11:36:45.756745    7093 check.go:245] Used auditConfig
I1026 11:36:45.756751    7093 check.go:277] Returning from execute on tests: finalOutput &check.testOutput{testResult:true, flagFound:false, actualResult:"{\n  \"kind\": \"KubeletConfiguration\",\n  \"apiVersion\": \"kubelet.config.k8s.io/v1beta1\",\n  \"address\": \"0.0.0.0\",\n  \"authentication\": {\n    \"anonymous\": {\n      \"enabled\": false\n    },\n    \"webhook\": {\n      \"cacheTTL\": \"2m0s\",\n      \"enabled\": true\n    },\n    \"x509\": {\n      \"clientCAFile\": \"/etc/kubernetes/pki/ca.crt\"\n    }\n  },\n  \"authorization\": {\n    \"mode\": \"Webhook\",\n    \"webhook\": {\n      \"cacheAuthorizedTTL\": \"5m0s\",\n      \"cacheUnauthorizedTTL\": \"30s\"\n    }\n  },\n  \"clusterDomain\": \"cluster.local\",\n  \"hairpinMode\": \"hairpin-veth\",\n  \"readOnlyPort\": 0,\n  \"cgroupDriver\": \"cgroupfs\",\n  \"cgroupRoot\": \"/\",\n  \"featureGates\": {\n    \"RotateKubeletServerCertificate\": true\n  },\n  \"protectKernelDefaults\": true,\n  \"serializeImagePulls\": false,\n  \"serverTLSBootstrap\": true,\n  \"tlsCipherSuites\": [\n    \"TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256\",\n    \"TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256\",\n    \"TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305\",\n    \"TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384\",\n    \"TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305\",\n    \"TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384\",\n    \"TLS_RSA_WITH_AES_256_GCM_SHA384\",\n    \"TLS_RSA_WITH_AES_128_GCM_SHA256\"\n  ],\n  \"clusterDNS\": [\n    \"172.20.0.10\"\n  ],\n  \"evictionHard\": {\n    \"memory.available\": \"100Mi\",\n    \"nodefs.available\": \"10%\",\n    \"nodefs.inodesFree\": \"5%\"\n  },\n  \"kubeReserved\": {\n    \"cpu\": \"70m\",\n    \"ephemeral-storage\": \"1Gi\",\n    \"memory\": \"574Mi\"\n  }\n}", ExpectedResult:"'{.readOnlyPort}' is equal to '0'"}
I1026 11:36:45.756809    7093 check.go:184] Command: "/bin/cat /etc/kubernetes/kubelet/kubelet-config.json" TestResult: true State: "PASS" 
I1026 11:36:45.756819    7093 check.go:110] -----   Running check 3.2.5   -----
I1026 11:36:45.761354    7093 check.go:299] Command: "/bin/ps -fC kubelet"
I1026 11:36:45.761376    7093 check.go:300] Output:
 "UID        PID  PPID  C STIME TTY          TIME CMD\nroot      3276     1  0 07:56 ?        00:02:11 /usr/bin/kubelet --cloud-provider aws --config /etc/kubernetes/kubelet/kubelet-config.json --kubeconfig /var/lib/kubelet/kubeconfig --container-runtime docker --network-plugin cni --node-ip=10.42.11.122 --pod-infra-container-image=602401143452.dkr.ecr.us-west-2.amazonaws.com/eks/pause:3.5 --v=2 --max-pods=110\n"
I1026 11:36:45.762208    7093 check.go:299] Command: "/bin/cat /etc/kubernetes/kubelet/kubelet-config.json"
I1026 11:36:45.762221    7093 check.go:300] Output:
 "{\n  \"kind\": \"KubeletConfiguration\",\n  \"apiVersion\": \"kubelet.config.k8s.io/v1beta1\",\n  \"address\": \"0.0.0.0\",\n  \"authentication\": {\n    \"anonymous\": {\n      \"enabled\": false\n    },\n    \"webhook\": {\n      \"cacheTTL\": \"2m0s\",\n      \"enabled\": true\n    },\n    \"x509\": {\n      \"clientCAFile\": \"/etc/kubernetes/pki/ca.crt\"\n    }\n  },\n  \"authorization\": {\n    \"mode\": \"Webhook\",\n    \"webhook\": {\n      \"cacheAuthorizedTTL\": \"5m0s\",\n      \"cacheUnauthorizedTTL\": \"30s\"\n    }\n  },\n  \"clusterDomain\": \"cluster.local\",\n  \"hairpinMode\": \"hairpin-veth\",\n  \"readOnlyPort\": 0,\n  \"cgroupDriver\": \"cgroupfs\",\n  \"cgroupRoot\": \"/\",\n  \"featureGates\": {\n    \"RotateKubeletServerCertificate\": true\n  },\n  \"protectKernelDefaults\": true,\n  \"serializeImagePulls\": false,\n  \"serverTLSBootstrap\": true,\n  \"tlsCipherSuites\": [\n    \"TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256\",\n    \"TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256\",\n    \"TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305\",\n    \"TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384\",\n    \"TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305\",\n    \"TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384\",\n    \"TLS_RSA_WITH_AES_256_GCM_SHA384\",\n    \"TLS_RSA_WITH_AES_128_GCM_SHA256\"\n  ],\n  \"clusterDNS\": [\n    \"172.20.0.10\"\n  ],\n  \"evictionHard\": {\n    \"memory.available\": \"100Mi\",\n    \"nodefs.available\": \"10%\",\n    \"nodefs.inodesFree\": \"5%\"\n  },\n  \"kubeReserved\": {\n    \"cpu\": \"70m\",\n    \"ephemeral-storage\": \"1Gi\",\n    \"memory\": \"574Mi\"\n  }\n}\n"
I1026 11:36:45.762275    7093 check.go:221] Running 2 test_items
I1026 11:36:45.762282    7093 test.go:153] In flagTestItem.findValue 
I1026 11:36:45.762289    7093 test.go:247] Flag '--streaming-connection-idle-timeout' does not exist
I1026 11:36:45.762380    7093 test.go:171] In pathTestItem.findValue 
I1026 11:36:45.762388    7093 test.go:249] Path '{.streamingConnectionIdleTimeout}' does not exist
I1026 11:36:45.762394    7093 check.go:245] Used auditConfig
I1026 11:36:45.762419    7093 test.go:153] In flagTestItem.findValue 
I1026 11:36:45.762427    7093 test.go:247] Flag '--streaming-connection-idle-timeout' does not exist
I1026 11:36:45.762505    7093 test.go:171] In pathTestItem.findValue 
I1026 11:36:45.762517    7093 test.go:249] Path '{.streamingConnectionIdleTimeout}' does not exist
I1026 11:36:45.762521    7093 check.go:245] Used auditConfig
I1026 11:36:45.762528    7093 check.go:277] Returning from execute on tests: finalOutput &check.testOutput{testResult:true, flagFound:false, actualResult:"{\n  \"kind\": \"KubeletConfiguration\",\n  \"apiVersion\": \"kubelet.config.k8s.io/v1beta1\",\n  \"address\": \"0.0.0.0\",\n  \"authentication\": {\n    \"anonymous\": {\n      \"enabled\": false\n    },\n    \"webhook\": {\n      \"cacheTTL\": \"2m0s\",\n      \"enabled\": true\n    },\n    \"x509\": {\n      \"clientCAFile\": \"/etc/kubernetes/pki/ca.crt\"\n    }\n  },\n  \"authorization\": {\n    \"mode\": \"Webhook\",\n    \"webhook\": {\n      \"cacheAuthorizedTTL\": \"5m0s\",\n      \"cacheUnauthorizedTTL\": \"30s\"\n    }\n  },\n  \"clusterDomain\": \"cluster.local\",\n  \"hairpinMode\": \"hairpin-veth\",\n  \"readOnlyPort\": 0,\n  \"cgroupDriver\": \"cgroupfs\",\n  \"cgroupRoot\": \"/\",\n  \"featureGates\": {\n    \"RotateKubeletServerCertificate\": true\n  },\n  \"protectKernelDefaults\": true,\n  \"serializeImagePulls\": false,\n  \"serverTLSBootstrap\": true,\n  \"tlsCipherSuites\": [\n    \"TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256\",\n    \"TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256\",\n    \"TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305\",\n    \"TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384\",\n    \"TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305\",\n    \"TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384\",\n    \"TLS_RSA_WITH_AES_256_GCM_SHA384\",\n    \"TLS_RSA_WITH_AES_128_GCM_SHA256\"\n  ],\n  \"clusterDNS\": [\n    \"172.20.0.10\"\n  ],\n  \"evictionHard\": {\n    \"memory.available\": \"100Mi\",\n    \"nodefs.available\": \"10%\",\n    \"nodefs.inodesFree\": \"5%\"\n  },\n  \"kubeReserved\": {\n    \"cpu\": \"70m\",\n    \"ephemeral-storage\": \"1Gi\",\n    \"memory\": \"574Mi\"\n  }\n}", ExpectedResult:"'{.streamingConnectionIdleTimeout}' is present OR '{.streamingConnectionIdleTimeout}' is not present"}
I1026 11:36:45.762576    7093 check.go:184] Command: "/bin/cat /etc/kubernetes/kubelet/kubelet-config.json" TestResult: true State: "PASS" 
I1026 11:36:45.762587    7093 check.go:110] -----   Running check 3.2.6   -----
I1026 11:36:45.766965    7093 check.go:299] Command: "/bin/ps -fC kubelet"
I1026 11:36:45.766977    7093 check.go:300] Output:
 "UID        PID  PPID  C STIME TTY          TIME CMD\nroot      3276     1  0 07:56 ?        00:02:11 /usr/bin/kubelet --cloud-provider aws --config /etc/kubernetes/kubelet/kubelet-config.json --kubeconfig /var/lib/kubelet/kubeconfig --container-runtime docker --network-plugin cni --node-ip=10.42.11.122 --pod-infra-container-image=602401143452.dkr.ecr.us-west-2.amazonaws.com/eks/pause:3.5 --v=2 --max-pods=110\n"
I1026 11:36:45.767802    7093 check.go:299] Command: "/bin/cat /etc/kubernetes/kubelet/kubelet-config.json"
I1026 11:36:45.767822    7093 check.go:300] Output:
 "{\n  \"kind\": \"KubeletConfiguration\",\n  \"apiVersion\": \"kubelet.config.k8s.io/v1beta1\",\n  \"address\": \"0.0.0.0\",\n  \"authentication\": {\n    \"anonymous\": {\n      \"enabled\": false\n    },\n    \"webhook\": {\n      \"cacheTTL\": \"2m0s\",\n      \"enabled\": true\n    },\n    \"x509\": {\n      \"clientCAFile\": \"/etc/kubernetes/pki/ca.crt\"\n    }\n  },\n  \"authorization\": {\n    \"mode\": \"Webhook\",\n    \"webhook\": {\n      \"cacheAuthorizedTTL\": \"5m0s\",\n      \"cacheUnauthorizedTTL\": \"30s\"\n    }\n  },\n  \"clusterDomain\": \"cluster.local\",\n  \"hairpinMode\": \"hairpin-veth\",\n  \"readOnlyPort\": 0,\n  \"cgroupDriver\": \"cgroupfs\",\n  \"cgroupRoot\": \"/\",\n  \"featureGates\": {\n    \"RotateKubeletServerCertificate\": true\n  },\n  \"protectKernelDefaults\": true,\n  \"serializeImagePulls\": false,\n  \"serverTLSBootstrap\": true,\n  \"tlsCipherSuites\": [\n    \"TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256\",\n    \"TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256\",\n    \"TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305\",\n    \"TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384\",\n    \"TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305\",\n    \"TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384\",\n    \"TLS_RSA_WITH_AES_256_GCM_SHA384\",\n    \"TLS_RSA_WITH_AES_128_GCM_SHA256\"\n  ],\n  \"clusterDNS\": [\n    \"172.20.0.10\"\n  ],\n  \"evictionHard\": {\n    \"memory.available\": \"100Mi\",\n    \"nodefs.available\": \"10%\",\n    \"nodefs.inodesFree\": \"5%\"\n  },\n  \"kubeReserved\": {\n    \"cpu\": \"70m\",\n    \"ephemeral-storage\": \"1Gi\",\n    \"memory\": \"574Mi\"\n  }\n}\n"
I1026 11:36:45.767861    7093 check.go:221] Running 1 test_items
I1026 11:36:45.767869    7093 test.go:153] In flagTestItem.findValue 
I1026 11:36:45.767888    7093 test.go:247] Flag '--protect-kernel-defaults' does not exist
I1026 11:36:45.767997    7093 test.go:171] In pathTestItem.findValue true
I1026 11:36:45.768013    7093 test.go:249] Path '{.protectKernelDefaults}' exists
I1026 11:36:45.768018    7093 check.go:245] Used auditConfig
I1026 11:36:45.768025    7093 check.go:277] Returning from execute on tests: finalOutput &check.testOutput{testResult:true, flagFound:false, actualResult:"{\n  \"kind\": \"KubeletConfiguration\",\n  \"apiVersion\": \"kubelet.config.k8s.io/v1beta1\",\n  \"address\": \"0.0.0.0\",\n  \"authentication\": {\n    \"anonymous\": {\n      \"enabled\": false\n    },\n    \"webhook\": {\n      \"cacheTTL\": \"2m0s\",\n      \"enabled\": true\n    },\n    \"x509\": {\n      \"clientCAFile\": \"/etc/kubernetes/pki/ca.crt\"\n    }\n  },\n  \"authorization\": {\n    \"mode\": \"Webhook\",\n    \"webhook\": {\n      \"cacheAuthorizedTTL\": \"5m0s\",\n      \"cacheUnauthorizedTTL\": \"30s\"\n    }\n  },\n  \"clusterDomain\": \"cluster.local\",\n  \"hairpinMode\": \"hairpin-veth\",\n  \"readOnlyPort\": 0,\n  \"cgroupDriver\": \"cgroupfs\",\n  \"cgroupRoot\": \"/\",\n  \"featureGates\": {\n    \"RotateKubeletServerCertificate\": true\n  },\n  \"protectKernelDefaults\": true,\n  \"serializeImagePulls\": false,\n  \"serverTLSBootstrap\": true,\n  \"tlsCipherSuites\": [\n    \"TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256\",\n    \"TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256\",\n    \"TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305\",\n    \"TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384\",\n    \"TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305\",\n    \"TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384\",\n    \"TLS_RSA_WITH_AES_256_GCM_SHA384\",\n    \"TLS_RSA_WITH_AES_128_GCM_SHA256\"\n  ],\n  \"clusterDNS\": [\n    \"172.20.0.10\"\n  ],\n  \"evictionHard\": {\n    \"memory.available\": \"100Mi\",\n    \"nodefs.available\": \"10%\",\n    \"nodefs.inodesFree\": \"5%\"\n  },\n  \"kubeReserved\": {\n    \"cpu\": \"70m\",\n    \"ephemeral-storage\": \"1Gi\",\n    \"memory\": \"574Mi\"\n  }\n}", ExpectedResult:"'{.protectKernelDefaults}' is equal to 'true'"}
I1026 11:36:45.768080    7093 check.go:184] Command: "/bin/cat /etc/kubernetes/kubelet/kubelet-config.json" TestResult: true State: "PASS" 
I1026 11:36:45.768138    7093 check.go:110] -----   Running check 3.2.7   -----
I1026 11:36:45.772614    7093 check.go:299] Command: "/bin/ps -fC kubelet"
I1026 11:36:45.772626    7093 check.go:300] Output:
 "UID        PID  PPID  C STIME TTY          TIME CMD\nroot      3276     1  0 07:56 ?        00:02:11 /usr/bin/kubelet --cloud-provider aws --config /etc/kubernetes/kubelet/kubelet-config.json --kubeconfig /var/lib/kubelet/kubeconfig --container-runtime docker --network-plugin cni --node-ip=10.42.11.122 --pod-infra-container-image=602401143452.dkr.ecr.us-west-2.amazonaws.com/eks/pause:3.5 --v=2 --max-pods=110\n"
I1026 11:36:45.773537    7093 check.go:299] Command: "/bin/cat /etc/kubernetes/kubelet/kubelet-config.json"
I1026 11:36:45.773549    7093 check.go:300] Output:
 "{\n  \"kind\": \"KubeletConfiguration\",\n  \"apiVersion\": \"kubelet.config.k8s.io/v1beta1\",\n  \"address\": \"0.0.0.0\",\n  \"authentication\": {\n    \"anonymous\": {\n      \"enabled\": false\n    },\n    \"webhook\": {\n      \"cacheTTL\": \"2m0s\",\n      \"enabled\": true\n    },\n    \"x509\": {\n      \"clientCAFile\": \"/etc/kubernetes/pki/ca.crt\"\n    }\n  },\n  \"authorization\": {\n    \"mode\": \"Webhook\",\n    \"webhook\": {\n      \"cacheAuthorizedTTL\": \"5m0s\",\n      \"cacheUnauthorizedTTL\": \"30s\"\n    }\n  },\n  \"clusterDomain\": \"cluster.local\",\n  \"hairpinMode\": \"hairpin-veth\",\n  \"readOnlyPort\": 0,\n  \"cgroupDriver\": \"cgroupfs\",\n  \"cgroupRoot\": \"/\",\n  \"featureGates\": {\n    \"RotateKubeletServerCertificate\": true\n  },\n  \"protectKernelDefaults\": true,\n  \"serializeImagePulls\": false,\n  \"serverTLSBootstrap\": true,\n  \"tlsCipherSuites\": [\n    \"TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256\",\n    \"TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256\",\n    \"TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305\",\n    \"TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384\",\n    \"TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305\",\n    \"TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384\",\n    \"TLS_RSA_WITH_AES_256_GCM_SHA384\",\n    \"TLS_RSA_WITH_AES_128_GCM_SHA256\"\n  ],\n  \"clusterDNS\": [\n    \"172.20.0.10\"\n  ],\n  \"evictionHard\": {\n    \"memory.available\": \"100Mi\",\n    \"nodefs.available\": \"10%\",\n    \"nodefs.inodesFree\": \"5%\"\n  },\n  \"kubeReserved\": {\n    \"cpu\": \"70m\",\n    \"ephemeral-storage\": \"1Gi\",\n    \"memory\": \"574Mi\"\n  }\n}\n"
I1026 11:36:45.773593    7093 check.go:221] Running 2 test_items
I1026 11:36:45.773600    7093 test.go:153] In flagTestItem.findValue 
I1026 11:36:45.773608    7093 test.go:247] Flag '--make-iptables-util-chains' does not exist
I1026 11:36:45.773680    7093 test.go:171] In pathTestItem.findValue 
I1026 11:36:45.773687    7093 test.go:249] Path '{.makeIPTablesUtilChains}' does not exist
I1026 11:36:45.773692    7093 check.go:245] Used auditConfig
I1026 11:36:45.773705    7093 test.go:153] In flagTestItem.findValue 
I1026 11:36:45.773711    7093 test.go:247] Flag '--make-iptables-util-chains' does not exist
I1026 11:36:45.773770    7093 test.go:171] In pathTestItem.findValue 
I1026 11:36:45.773777    7093 test.go:249] Path '{.makeIPTablesUtilChains}' does not exist
I1026 11:36:45.773782    7093 check.go:245] Used auditConfig
I1026 11:36:45.773791    7093 check.go:277] Returning from execute on tests: finalOutput &check.testOutput{testResult:true, flagFound:false, actualResult:"{\n  \"kind\": \"KubeletConfiguration\",\n  \"apiVersion\": \"kubelet.config.k8s.io/v1beta1\",\n  \"address\": \"0.0.0.0\",\n  \"authentication\": {\n    \"anonymous\": {\n      \"enabled\": false\n    },\n    \"webhook\": {\n      \"cacheTTL\": \"2m0s\",\n      \"enabled\": true\n    },\n    \"x509\": {\n      \"clientCAFile\": \"/etc/kubernetes/pki/ca.crt\"\n    }\n  },\n  \"authorization\": {\n    \"mode\": \"Webhook\",\n    \"webhook\": {\n      \"cacheAuthorizedTTL\": \"5m0s\",\n      \"cacheUnauthorizedTTL\": \"30s\"\n    }\n  },\n  \"clusterDomain\": \"cluster.local\",\n  \"hairpinMode\": \"hairpin-veth\",\n  \"readOnlyPort\": 0,\n  \"cgroupDriver\": \"cgroupfs\",\n  \"cgroupRoot\": \"/\",\n  \"featureGates\": {\n    \"RotateKubeletServerCertificate\": true\n  },\n  \"protectKernelDefaults\": true,\n  \"serializeImagePulls\": false,\n  \"serverTLSBootstrap\": true,\n  \"tlsCipherSuites\": [\n    \"TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256\",\n    \"TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256\",\n    \"TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305\",\n    \"TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384\",\n    \"TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305\",\n    \"TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384\",\n    \"TLS_RSA_WITH_AES_256_GCM_SHA384\",\n    \"TLS_RSA_WITH_AES_128_GCM_SHA256\"\n  ],\n  \"clusterDNS\": [\n    \"172.20.0.10\"\n  ],\n  \"evictionHard\": {\n    \"memory.available\": \"100Mi\",\n    \"nodefs.available\": \"10%\",\n    \"nodefs.inodesFree\": \"5%\"\n  },\n  \"kubeReserved\": {\n    \"cpu\": \"70m\",\n    \"ephemeral-storage\": \"1Gi\",\n    \"memory\": \"574Mi\"\n  }\n}", ExpectedResult:"'{.makeIPTablesUtilChains}' is present OR '{.makeIPTablesUtilChains}' is not present"}
I1026 11:36:45.773836    7093 check.go:184] Command: "/bin/cat /etc/kubernetes/kubelet/kubelet-config.json" TestResult: true State: "PASS" 
I1026 11:36:45.773845    7093 check.go:110] -----   Running check 3.2.8   -----
I1026 11:36:45.778513    7093 check.go:299] Command: "/bin/ps -fC kubelet"
I1026 11:36:45.778524    7093 check.go:300] Output:
 "UID        PID  PPID  C STIME TTY          TIME CMD\nroot      3276     1  0 07:56 ?        00:02:11 /usr/bin/kubelet --cloud-provider aws --config /etc/kubernetes/kubelet/kubelet-config.json --kubeconfig /var/lib/kubelet/kubeconfig --container-runtime docker --network-plugin cni --node-ip=10.42.11.122 --pod-infra-container-image=602401143452.dkr.ecr.us-west-2.amazonaws.com/eks/pause:3.5 --v=2 --max-pods=110\n"
I1026 11:36:45.778572    7093 check.go:221] Running 1 test_items
I1026 11:36:45.778586    7093 test.go:153] In flagTestItem.findValue 
I1026 11:36:45.778594    7093 test.go:247] Flag '--hostname-override' does not exist
I1026 11:36:45.778598    7093 check.go:245] Used auditCommand
I1026 11:36:45.778605    7093 check.go:277] Returning from execute on tests: finalOutput &check.testOutput{testResult:true, flagFound:false, actualResult:"UID        PID  PPID  C STIME TTY          TIME CMD\nroot      3276     1  0 07:56 ?        00:02:11 /usr/bin/kubelet --cloud-provider aws --config /etc/kubernetes/kubelet/kubelet-config.json --kubeconfig /var/lib/kubelet/kubeconfig --container-runtime docker --network-plugin cni --node-ip=10.42.11.122 --pod-infra-container-image=602401143452.dkr.ecr.us-west-2.amazonaws.com/eks/pause:3.5 --v=2 --max-pods=110", ExpectedResult:"'--hostname-override' is not present"}
I1026 11:36:45.778626    7093 check.go:184] Command: "" TestResult: true State: "PASS" 
I1026 11:36:45.778653    7093 check.go:110] -----   Running check 3.2.9   -----
I1026 11:36:45.783098    7093 check.go:299] Command: "/bin/ps -fC kubelet"
I1026 11:36:45.783110    7093 check.go:300] Output:
 "UID        PID  PPID  C STIME TTY          TIME CMD\nroot      3276     1  0 07:56 ?        00:02:11 /usr/bin/kubelet --cloud-provider aws --config /etc/kubernetes/kubelet/kubelet-config.json --kubeconfig /var/lib/kubelet/kubeconfig --container-runtime docker --network-plugin cni --node-ip=10.42.11.122 --pod-infra-container-image=602401143452.dkr.ecr.us-west-2.amazonaws.com/eks/pause:3.5 --v=2 --max-pods=110\n"
I1026 11:36:45.783869    7093 check.go:299] Command: "/bin/cat /etc/kubernetes/kubelet/kubelet-config.json"
I1026 11:36:45.783881    7093 check.go:300] Output:
 "{\n  \"kind\": \"KubeletConfiguration\",\n  \"apiVersion\": \"kubelet.config.k8s.io/v1beta1\",\n  \"address\": \"0.0.0.0\",\n  \"authentication\": {\n    \"anonymous\": {\n      \"enabled\": false\n    },\n    \"webhook\": {\n      \"cacheTTL\": \"2m0s\",\n      \"enabled\": true\n    },\n    \"x509\": {\n      \"clientCAFile\": \"/etc/kubernetes/pki/ca.crt\"\n    }\n  },\n  \"authorization\": {\n    \"mode\": \"Webhook\",\n    \"webhook\": {\n      \"cacheAuthorizedTTL\": \"5m0s\",\n      \"cacheUnauthorizedTTL\": \"30s\"\n    }\n  },\n  \"clusterDomain\": \"cluster.local\",\n  \"hairpinMode\": \"hairpin-veth\",\n  \"readOnlyPort\": 0,\n  \"cgroupDriver\": \"cgroupfs\",\n  \"cgroupRoot\": \"/\",\n  \"featureGates\": {\n    \"RotateKubeletServerCertificate\": true\n  },\n  \"protectKernelDefaults\": true,\n  \"serializeImagePulls\": false,\n  \"serverTLSBootstrap\": true,\n  \"tlsCipherSuites\": [\n    \"TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256\",\n    \"TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256\",\n    \"TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305\",\n    \"TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384\",\n    \"TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305\",\n    \"TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384\",\n    \"TLS_RSA_WITH_AES_256_GCM_SHA384\",\n    \"TLS_RSA_WITH_AES_128_GCM_SHA256\"\n  ],\n  \"clusterDNS\": [\n    \"172.20.0.10\"\n  ],\n  \"evictionHard\": {\n    \"memory.available\": \"100Mi\",\n    \"nodefs.available\": \"10%\",\n    \"nodefs.inodesFree\": \"5%\"\n  },\n  \"kubeReserved\": {\n    \"cpu\": \"70m\",\n    \"ephemeral-storage\": \"1Gi\",\n    \"memory\": \"574Mi\"\n  }\n}\n"
I1026 11:36:45.783945    7093 check.go:221] Running 1 test_items
I1026 11:36:45.783958    7093 test.go:153] In flagTestItem.findValue 
I1026 11:36:45.783965    7093 test.go:247] Flag '--event-qps' does not exist
I1026 11:36:45.784069    7093 test.go:171] In pathTestItem.findValue 
I1026 11:36:45.784080    7093 test.go:249] Path '{.eventRecordQPS}' does not exist
I1026 11:36:45.784085    7093 check.go:245] Used auditConfig
I1026 11:36:45.784091    7093 check.go:277] Returning from execute on tests: finalOutput &check.testOutput{testResult:false, flagFound:false, actualResult:"{\n  \"kind\": \"KubeletConfiguration\",\n  \"apiVersion\": \"kubelet.config.k8s.io/v1beta1\",\n  \"address\": \"0.0.0.0\",\n  \"authentication\": {\n    \"anonymous\": {\n      \"enabled\": false\n    },\n    \"webhook\": {\n      \"cacheTTL\": \"2m0s\",\n      \"enabled\": true\n    },\n    \"x509\": {\n      \"clientCAFile\": \"/etc/kubernetes/pki/ca.crt\"\n    }\n  },\n  \"authorization\": {\n    \"mode\": \"Webhook\",\n    \"webhook\": {\n      \"cacheAuthorizedTTL\": \"5m0s\",\n      \"cacheUnauthorizedTTL\": \"30s\"\n    }\n  },\n  \"clusterDomain\": \"cluster.local\",\n  \"hairpinMode\": \"hairpin-veth\",\n  \"readOnlyPort\": 0,\n  \"cgroupDriver\": \"cgroupfs\",\n  \"cgroupRoot\": \"/\",\n  \"featureGates\": {\n    \"RotateKubeletServerCertificate\": true\n  },\n  \"protectKernelDefaults\": true,\n  \"serializeImagePulls\": false,\n  \"serverTLSBootstrap\": true,\n  \"tlsCipherSuites\": [\n    \"TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256\",\n    \"TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256\",\n    \"TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305\",\n    \"TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384\",\n    \"TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305\",\n    \"TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384\",\n    \"TLS_RSA_WITH_AES_256_GCM_SHA384\",\n    \"TLS_RSA_WITH_AES_128_GCM_SHA256\"\n  ],\n  \"clusterDNS\": [\n    \"172.20.0.10\"\n  ],\n  \"evictionHard\": {\n    \"memory.available\": \"100Mi\",\n    \"nodefs.available\": \"10%\",\n    \"nodefs.inodesFree\": \"5%\"\n  },\n  \"kubeReserved\": {\n    \"cpu\": \"70m\",\n    \"ephemeral-storage\": \"1Gi\",\n    \"memory\": \"574Mi\"\n  }\n}", ExpectedResult:"'{.eventRecordQPS}' is present"}
I1026 11:36:45.784139    7093 check.go:184] Command: "/bin/cat /etc/kubernetes/kubelet/kubelet-config.json" TestResult: false State: "WARN" 
I1026 11:36:45.784148    7093 check.go:110] -----   Running check 3.2.10   -----
I1026 11:36:45.788541    7093 check.go:299] Command: "/bin/ps -fC kubelet"
I1026 11:36:45.788553    7093 check.go:300] Output:
 "UID        PID  PPID  C STIME TTY          TIME CMD\nroot      3276     1  0 07:56 ?        00:02:11 /usr/bin/kubelet --cloud-provider aws --config /etc/kubernetes/kubelet/kubelet-config.json --kubeconfig /var/lib/kubelet/kubeconfig --container-runtime docker --network-plugin cni --node-ip=10.42.11.122 --pod-infra-container-image=602401143452.dkr.ecr.us-west-2.amazonaws.com/eks/pause:3.5 --v=2 --max-pods=110\n"
I1026 11:36:45.789367    7093 check.go:299] Command: "/bin/cat /etc/kubernetes/kubelet/kubelet-config.json"
I1026 11:36:45.789379    7093 check.go:300] Output:
 "{\n  \"kind\": \"KubeletConfiguration\",\n  \"apiVersion\": \"kubelet.config.k8s.io/v1beta1\",\n  \"address\": \"0.0.0.0\",\n  \"authentication\": {\n    \"anonymous\": {\n      \"enabled\": false\n    },\n    \"webhook\": {\n      \"cacheTTL\": \"2m0s\",\n      \"enabled\": true\n    },\n    \"x509\": {\n      \"clientCAFile\": \"/etc/kubernetes/pki/ca.crt\"\n    }\n  },\n  \"authorization\": {\n    \"mode\": \"Webhook\",\n    \"webhook\": {\n      \"cacheAuthorizedTTL\": \"5m0s\",\n      \"cacheUnauthorizedTTL\": \"30s\"\n    }\n  },\n  \"clusterDomain\": \"cluster.local\",\n  \"hairpinMode\": \"hairpin-veth\",\n  \"readOnlyPort\": 0,\n  \"cgroupDriver\": \"cgroupfs\",\n  \"cgroupRoot\": \"/\",\n  \"featureGates\": {\n    \"RotateKubeletServerCertificate\": true\n  },\n  \"protectKernelDefaults\": true,\n  \"serializeImagePulls\": false,\n  \"serverTLSBootstrap\": true,\n  \"tlsCipherSuites\": [\n    \"TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256\",\n    \"TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256\",\n    \"TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305\",\n    \"TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384\",\n    \"TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305\",\n    \"TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384\",\n    \"TLS_RSA_WITH_AES_256_GCM_SHA384\",\n    \"TLS_RSA_WITH_AES_128_GCM_SHA256\"\n  ],\n  \"clusterDNS\": [\n    \"172.20.0.10\"\n  ],\n  \"evictionHard\": {\n    \"memory.available\": \"100Mi\",\n    \"nodefs.available\": \"10%\",\n    \"nodefs.inodesFree\": \"5%\"\n  },\n  \"kubeReserved\": {\n    \"cpu\": \"70m\",\n    \"ephemeral-storage\": \"1Gi\",\n    \"memory\": \"574Mi\"\n  }\n}\n"
I1026 11:36:45.789417    7093 check.go:221] Running 2 test_items
I1026 11:36:45.789431    7093 test.go:153] In flagTestItem.findValue 
I1026 11:36:45.789439    7093 test.go:247] Flag '--rotate-certificates' does not exist
I1026 11:36:45.789547    7093 test.go:171] In pathTestItem.findValue 
I1026 11:36:45.789555    7093 test.go:249] Path '{.rotateCertificates}' does not exist
I1026 11:36:45.789561    7093 check.go:245] Used auditConfig
I1026 11:36:45.789567    7093 test.go:153] In flagTestItem.findValue 
I1026 11:36:45.789573    7093 test.go:247] Flag '--rotate-certificates' does not exist
I1026 11:36:45.789622    7093 test.go:171] In pathTestItem.findValue 
I1026 11:36:45.789629    7093 test.go:249] Path '{.rotateCertificates}' does not exist
I1026 11:36:45.789636    7093 check.go:245] Used auditConfig
I1026 11:36:45.789642    7093 check.go:277] Returning from execute on tests: finalOutput &check.testOutput{testResult:true, flagFound:false, actualResult:"{\n  \"kind\": \"KubeletConfiguration\",\n  \"apiVersion\": \"kubelet.config.k8s.io/v1beta1\",\n  \"address\": \"0.0.0.0\",\n  \"authentication\": {\n    \"anonymous\": {\n      \"enabled\": false\n    },\n    \"webhook\": {\n      \"cacheTTL\": \"2m0s\",\n      \"enabled\": true\n    },\n    \"x509\": {\n      \"clientCAFile\": \"/etc/kubernetes/pki/ca.crt\"\n    }\n  },\n  \"authorization\": {\n    \"mode\": \"Webhook\",\n    \"webhook\": {\n      \"cacheAuthorizedTTL\": \"5m0s\",\n      \"cacheUnauthorizedTTL\": \"30s\"\n    }\n  },\n  \"clusterDomain\": \"cluster.local\",\n  \"hairpinMode\": \"hairpin-veth\",\n  \"readOnlyPort\": 0,\n  \"cgroupDriver\": \"cgroupfs\",\n  \"cgroupRoot\": \"/\",\n  \"featureGates\": {\n    \"RotateKubeletServerCertificate\": true\n  },\n  \"protectKernelDefaults\": true,\n  \"serializeImagePulls\": false,\n  \"serverTLSBootstrap\": true,\n  \"tlsCipherSuites\": [\n    \"TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256\",\n    \"TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256\",\n    \"TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305\",\n    \"TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384\",\n    \"TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305\",\n    \"TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384\",\n    \"TLS_RSA_WITH_AES_256_GCM_SHA384\",\n    \"TLS_RSA_WITH_AES_128_GCM_SHA256\"\n  ],\n  \"clusterDNS\": [\n    \"172.20.0.10\"\n  ],\n  \"evictionHard\": {\n    \"memory.available\": \"100Mi\",\n    \"nodefs.available\": \"10%\",\n    \"nodefs.inodesFree\": \"5%\"\n  },\n  \"kubeReserved\": {\n    \"cpu\": \"70m\",\n    \"ephemeral-storage\": \"1Gi\",\n    \"memory\": \"574Mi\"\n  }\n}", ExpectedResult:"'{.rotateCertificates}' is present OR '{.rotateCertificates}' is not present"}
I1026 11:36:45.789693    7093 check.go:184] Command: "/bin/cat /etc/kubernetes/kubelet/kubelet-config.json" TestResult: true State: "PASS" 
I1026 11:36:45.789702    7093 check.go:110] -----   Running check 3.2.11   -----
I1026 11:36:45.794079    7093 check.go:299] Command: "/bin/ps -fC kubelet"
I1026 11:36:45.794092    7093 check.go:300] Output:
 "UID        PID  PPID  C STIME TTY          TIME CMD\nroot      3276     1  0 07:56 ?        00:02:11 /usr/bin/kubelet --cloud-provider aws --config /etc/kubernetes/kubelet/kubelet-config.json --kubeconfig /var/lib/kubelet/kubeconfig --container-runtime docker --network-plugin cni --node-ip=10.42.11.122 --pod-infra-container-image=602401143452.dkr.ecr.us-west-2.amazonaws.com/eks/pause:3.5 --v=2 --max-pods=110\n"
I1026 11:36:45.794869    7093 check.go:299] Command: "/bin/cat /etc/kubernetes/kubelet/kubelet-config.json"
I1026 11:36:45.794882    7093 check.go:300] Output:
 "{\n  \"kind\": \"KubeletConfiguration\",\n  \"apiVersion\": \"kubelet.config.k8s.io/v1beta1\",\n  \"address\": \"0.0.0.0\",\n  \"authentication\": {\n    \"anonymous\": {\n      \"enabled\": false\n    },\n    \"webhook\": {\n      \"cacheTTL\": \"2m0s\",\n      \"enabled\": true\n    },\n    \"x509\": {\n      \"clientCAFile\": \"/etc/kubernetes/pki/ca.crt\"\n    }\n  },\n  \"authorization\": {\n    \"mode\": \"Webhook\",\n    \"webhook\": {\n      \"cacheAuthorizedTTL\": \"5m0s\",\n      \"cacheUnauthorizedTTL\": \"30s\"\n    }\n  },\n  \"clusterDomain\": \"cluster.local\",\n  \"hairpinMode\": \"hairpin-veth\",\n  \"readOnlyPort\": 0,\n  \"cgroupDriver\": \"cgroupfs\",\n  \"cgroupRoot\": \"/\",\n  \"featureGates\": {\n    \"RotateKubeletServerCertificate\": true\n  },\n  \"protectKernelDefaults\": true,\n  \"serializeImagePulls\": false,\n  \"serverTLSBootstrap\": true,\n  \"tlsCipherSuites\": [\n    \"TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256\",\n    \"TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256\",\n    \"TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305\",\n    \"TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384\",\n    \"TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305\",\n    \"TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384\",\n    \"TLS_RSA_WITH_AES_256_GCM_SHA384\",\n    \"TLS_RSA_WITH_AES_128_GCM_SHA256\"\n  ],\n  \"clusterDNS\": [\n    \"172.20.0.10\"\n  ],\n  \"evictionHard\": {\n    \"memory.available\": \"100Mi\",\n    \"nodefs.available\": \"10%\",\n    \"nodefs.inodesFree\": \"5%\"\n  },\n  \"kubeReserved\": {\n    \"cpu\": \"70m\",\n    \"ephemeral-storage\": \"1Gi\",\n    \"memory\": \"574Mi\"\n  }\n}\n"
I1026 11:36:45.794929    7093 check.go:221] Running 1 test_items
I1026 11:36:45.795232    7093 test.go:153] In flagTestItem.findValue 
I1026 11:36:45.795320    7093 test.go:247] Flag 'RotateKubeletServerCertificate' does not exist
I1026 11:36:45.795470    7093 test.go:171] In pathTestItem.findValue true
I1026 11:36:45.795533    7093 test.go:249] Path '{.featureGates.RotateKubeletServerCertificate}' exists
I1026 11:36:45.795585    7093 check.go:245] Used auditConfig
I1026 11:36:45.795649    7093 check.go:277] Returning from execute on tests: finalOutput &check.testOutput{testResult:true, flagFound:false, actualResult:"{\n  \"kind\": \"KubeletConfiguration\",\n  \"apiVersion\": \"kubelet.config.k8s.io/v1beta1\",\n  \"address\": \"0.0.0.0\",\n  \"authentication\": {\n    \"anonymous\": {\n      \"enabled\": false\n    },\n    \"webhook\": {\n      \"cacheTTL\": \"2m0s\",\n      \"enabled\": true\n    },\n    \"x509\": {\n      \"clientCAFile\": \"/etc/kubernetes/pki/ca.crt\"\n    }\n  },\n  \"authorization\": {\n    \"mode\": \"Webhook\",\n    \"webhook\": {\n      \"cacheAuthorizedTTL\": \"5m0s\",\n      \"cacheUnauthorizedTTL\": \"30s\"\n    }\n  },\n  \"clusterDomain\": \"cluster.local\",\n  \"hairpinMode\": \"hairpin-veth\",\n  \"readOnlyPort\": 0,\n  \"cgroupDriver\": \"cgroupfs\",\n  \"cgroupRoot\": \"/\",\n  \"featureGates\": {\n    \"RotateKubeletServerCertificate\": true\n  },\n  \"protectKernelDefaults\": true,\n  \"serializeImagePulls\": false,\n  \"serverTLSBootstrap\": true,\n  \"tlsCipherSuites\": [\n    \"TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256\",\n    \"TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256\",\n    \"TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305\",\n    \"TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384\",\n    \"TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305\",\n    \"TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384\",\n    \"TLS_RSA_WITH_AES_256_GCM_SHA384\",\n    \"TLS_RSA_WITH_AES_128_GCM_SHA256\"\n  ],\n  \"clusterDNS\": [\n    \"172.20.0.10\"\n  ],\n  \"evictionHard\": {\n    \"memory.available\": \"100Mi\",\n    \"nodefs.available\": \"10%\",\n    \"nodefs.inodesFree\": \"5%\"\n  },\n  \"kubeReserved\": {\n    \"cpu\": \"70m\",\n    \"ephemeral-storage\": \"1Gi\",\n    \"memory\": \"574Mi\"\n  }\n}", ExpectedResult:"'{.featureGates.RotateKubeletServerCertificate}' is equal to 'true'"}
I1026 11:36:45.795776    7093 check.go:184] Command: "/bin/cat /etc/kubernetes/kubelet/kubelet-config.json" TestResult: true State: "PASS" 
I1026 11:36:45.795827    7093 check.go:110] -----   Running check 3.3.1   -----
I1026 11:36:45.795880    7093 check.go:145] No tests defined
I1026 11:36:45.796074    7093 root.go:119] == Running policies checks ==
I1026 11:36:45.796155    7093 util.go:126] Looking for config specific CIS version "eks-1.1.0"
I1026 11:36:45.796219    7093 util.go:130] Looking for file: cfg/eks-1.1.0/policies.yaml
I1026 11:36:45.796881    7093 common.go:273] Using config file: cfg/eks-1.1.0/config.yaml
I1026 11:36:45.796994    7093 common.go:79] Using test file: cfg/eks-1.1.0/policies.yaml
I1026 11:36:45.797540    7093 check.go:110] -----   Running check 4.1.1   -----
I1026 11:36:45.797556    7093 check.go:133] Test marked as a manual test
I1026 11:36:45.797561    7093 check.go:110] -----   Running check 4.1.2   -----
I1026 11:36:45.797566    7093 check.go:133] Test marked as a manual test
I1026 11:36:45.797623    7093 check.go:110] -----   Running check 4.1.3   -----
I1026 11:36:45.797638    7093 check.go:133] Test marked as a manual test
I1026 11:36:45.797642    7093 check.go:110] -----   Running check 4.1.4   -----
I1026 11:36:45.797742    7093 check.go:133] Test marked as a manual test
I1026 11:36:45.797787    7093 check.go:110] -----   Running check 4.1.5   -----
I1026 11:36:45.797797    7093 check.go:133] Test marked as a manual test
I1026 11:36:45.797801    7093 check.go:110] -----   Running check 4.1.6   -----
I1026 11:36:45.797807    7093 check.go:133] Test marked as a manual test
I1026 11:36:45.797811    7093 check.go:110] -----   Running check 4.2.1   -----
I1026 11:36:45.797816    7093 check.go:133] Test marked as a manual test
I1026 11:36:45.797821    7093 check.go:110] -----   Running check 4.2.2   -----
I1026 11:36:45.797825    7093 check.go:133] Test marked as a manual test
I1026 11:36:45.797830    7093 check.go:110] -----   Running check 4.2.3   -----
I1026 11:36:45.797835    7093 check.go:133] Test marked as a manual test
I1026 11:36:45.797840    7093 check.go:110] -----   Running check 4.2.4   -----
I1026 11:36:45.797845    7093 check.go:133] Test marked as a manual test
I1026 11:36:45.797849    7093 check.go:110] -----   Running check 4.2.5   -----
I1026 11:36:45.797855    7093 check.go:133] Test marked as a manual test
I1026 11:36:45.797859    7093 check.go:110] -----   Running check 4.2.6   -----
I1026 11:36:45.797865    7093 check.go:133] Test marked as a manual test
I1026 11:36:45.797869    7093 check.go:110] -----   Running check 4.2.7   -----
I1026 11:36:45.797874    7093 check.go:133] Test marked as a manual test
I1026 11:36:45.797878    7093 check.go:110] -----   Running check 4.2.8   -----
I1026 11:36:45.797884    7093 check.go:133] Test marked as a manual test
I1026 11:36:45.797888    7093 check.go:110] -----   Running check 4.2.9   -----
I1026 11:36:45.797893    7093 check.go:133] Test marked as a manual test
I1026 11:36:45.797897    7093 check.go:110] -----   Running check 4.3.1   -----
I1026 11:36:45.797903    7093 check.go:133] Test marked as a manual test
I1026 11:36:45.797908    7093 check.go:110] -----   Running check 4.3.2   -----
I1026 11:36:45.797919    7093 check.go:133] Test marked as a manual test
I1026 11:36:45.797925    7093 check.go:110] -----   Running check 4.4.1   -----
I1026 11:36:45.797930    7093 check.go:133] Test marked as a manual test
I1026 11:36:45.797935    7093 check.go:110] -----   Running check 4.4.2   -----
I1026 11:36:45.797941    7093 check.go:133] Test marked as a manual test
I1026 11:36:45.797945    7093 check.go:110] -----   Running check 4.6.1   -----
I1026 11:36:45.797951    7093 check.go:133] Test marked as a manual test
I1026 11:36:45.797956    7093 check.go:110] -----   Running check 4.6.2   -----
I1026 11:36:45.797961    7093 check.go:133] Test marked as a manual test
I1026 11:36:45.797965    7093 check.go:110] -----   Running check 4.6.3   -----
I1026 11:36:45.797971    7093 check.go:133] Test marked as a manual test
I1026 11:36:45.798029    7093 root.go:132] == Running managed services checks ==
I1026 11:36:45.798036    7093 util.go:126] Looking for config specific CIS version "eks-1.1.0"
I1026 11:36:45.798044    7093 util.go:130] Looking for file: cfg/eks-1.1.0/managedservices.yaml
I1026 11:36:45.798180    7093 common.go:273] Using config file: cfg/eks-1.1.0/config.yaml
I1026 11:36:45.798212    7093 common.go:79] Using test file: cfg/eks-1.1.0/managedservices.yaml
I1026 11:36:45.798561    7093 check.go:110] -----   Running check 5.1.1   -----
I1026 11:36:45.798578    7093 check.go:133] Test marked as a manual test
I1026 11:36:45.798584    7093 check.go:110] -----   Running check 5.1.2   -----
I1026 11:36:45.798589    7093 check.go:133] Test marked as a manual test
I1026 11:36:45.798593    7093 check.go:110] -----   Running check 5.1.3   -----
I1026 11:36:45.798604    7093 check.go:133] Test marked as a manual test
I1026 11:36:45.798611    7093 check.go:110] -----   Running check 5.1.4   -----
I1026 11:36:45.798616    7093 check.go:133] Test marked as a manual test
I1026 11:36:45.798620    7093 check.go:110] -----   Running check 5.2.1   -----
I1026 11:36:45.798626    7093 check.go:133] Test marked as a manual test
I1026 11:36:45.798630    7093 check.go:110] -----   Running check 5.3.1   -----
I1026 11:36:45.798636    7093 check.go:133] Test marked as a manual test
I1026 11:36:45.798640    7093 check.go:110] -----   Running check 5.4.1   -----
I1026 11:36:45.798646    7093 check.go:133] Test marked as a manual test
I1026 11:36:45.798650    7093 check.go:110] -----   Running check 5.4.2   -----
I1026 11:36:45.798655    7093 check.go:133] Test marked as a manual test
I1026 11:36:45.798661    7093 check.go:110] -----   Running check 5.4.3   -----
I1026 11:36:45.798666    7093 check.go:133] Test marked as a manual test
I1026 11:36:45.798670    7093 check.go:110] -----   Running check 5.4.4   -----
I1026 11:36:45.798675    7093 check.go:133] Test marked as a manual test
I1026 11:36:45.798679    7093 check.go:110] -----   Running check 5.4.5   -----
I1026 11:36:45.798685    7093 check.go:133] Test marked as a manual test
I1026 11:36:45.798689    7093 check.go:110] -----   Running check 5.5.1   -----
I1026 11:36:45.798694    7093 check.go:133] Test marked as a manual test
I1026 11:36:45.798699    7093 check.go:110] -----   Running check 5.6.1   -----
I1026 11:36:45.798704    7093 check.go:133] Test marked as a manual test
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