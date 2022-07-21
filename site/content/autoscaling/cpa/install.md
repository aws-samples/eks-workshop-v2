---
title: "CPA Install"
date: 2022-07-21T00:00:00-03:00
weight: 2
---

## CPA Installation using YAML Manifest

* Cluster proportional autoscaler can be installed using a helm chart or a YAML manifest.

* In this workshop, Cluster proportional autoscaler is installed as a `Deployment` object in the cluster in the `kube-system` namespace to avoid being evicted by itself or by the kubelet. We will use a YAML manifest to install CPA.

* The target deployment for the Cluster proportional autoscaler is `CoreDNS`

```bash
cat << EOF > cpa-install.yaml
---
kind: ServiceAccount
apiVersion: v1
metadata:
  name: dns-autoscaler
  namespace: kube-system
---
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: system:dns-autoscaler
rules:
  - apiGroups: [""]
    resources: ["nodes"]
    verbs: ["list", "watch"]
  - apiGroups: [""]
    resources: ["replicationcontrollers/scale"]
    verbs: ["get", "update"]
  - apiGroups: ["apps"]
    resources: ["deployments/scale", "replicasets/scale"]
    verbs: ["get", "update"]
  - apiGroups: [""]
    resources: ["configmaps"]
    verbs: ["get", "create"]
---
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: system:dns-autoscaler
subjects:
  - kind: ServiceAccount
    name: dns-autoscaler
    namespace: kube-system
roleRef:
  kind: ClusterRole
  name: system:dns-autoscaler
  apiGroup: rbac.authorization.k8s.io
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: dns-autoscaler
  namespace: kube-system
  labels:
    k8s-app: dns-autoscaler
    kubernetes.io/cluster-service: "true"
spec:
  selector:
    matchLabels:
      k8s-app: dns-autoscaler
  template:
    metadata:
      labels:
        k8s-app: dns-autoscaler
    spec:
      priorityClassName: system-cluster-critical
      securityContext:
        seccompProfile:
          type: RuntimeDefault
        supplementalGroups: [ 65534 ]
        fsGroup: 65534
      nodeSelector:
        kubernetes.io/os: linux
      containers:
      - name: autoscaler
        image: k8s.gcr.io/cpa/cluster-proportional-autoscaler:1.8.5
        resources:
            requests:
                cpu: "20m"
                memory: "10Mi"
        command:
          - /cluster-proportional-autoscaler
          - --namespace=kube-system
          - --configmap=dns-autoscaler
          - --target=Deployment/coredns
          # When cluster is using large nodes(with more cores), "coresPerReplica" should dominate.
          # If using small nodes, "nodesPerReplica" should dominate.
          - --default-params={"linear":{"coresPerReplica":256,"nodesPerReplica":16,"preventSinglePointFailure":true,"includeUnschedulableNodes":true}}
          - --logtostderr=true
          - --v=2
      tolerations:
      - key: "CriticalAddonsOnly"
        operator: "Exists"
      serviceAccountName: dns-autoscaler
EOF
```

```bash
kubectl apply -f cpa-install.yaml
```

Verify the deployment status by running the below command.

```bash
kubectl get deployment dns-autoscaler -n kube-system
```

{{< output >}}
NAME             READY   UP-TO-DATE   AVAILABLE   AGE
dns-autoscaler   1/1     1            1           10s
{{< /output >}}

```bash
kubectl get po -n kube-system -l k8s-app=dns-autoscaler
```

{{< output >}}
NAME                              READY   STATUS    RESTARTS   AGE
dns-autoscaler-7686459c58-cn97f   1/1     Running   0          1m
{{< /output >}}

Run the below command to check the configmap got created for the cluster proportional autoscaler

```bash
kubectl get configmap -n kube-system | grep dns-autoscaler
```

{{< output >}}
NAME               DATA   AGE
dns-autoscaler     1      1h
{{< /output >}}
