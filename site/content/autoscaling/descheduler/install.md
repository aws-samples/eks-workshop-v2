---
title: "Install"
date: 2022-06-09T00:00:00-03:00
weight: 2
---

## Configure the Descheduler

Lets get started by configuring the descheduler in the EKS cluster. The descheduler can be installed as `Job`, `CronJob`, `Deployment` in the cluster. It runs as a critical pod in the `kube-system` namespace to avoid being evicted by itself or by the kubelet.

In this workshop, descheduler installed as a `Deployment` object. Start by creating the descheduler policy configuration, we are enabling `RemovePodsViolatingNodeTaints`, `RemoveDuplicates`, `PodLifeTime`, `RemovePodsViolatingInterPodAntiAffinity`, `RemovePodsViolatingNodeAffinity`, `LowNodeUtilization` policies.

```bash
cat << EOF > descheduler-configmap.yaml
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: descheduler-policy-configmap
  namespace: kube-system
data:
  policy.yaml: |
    apiVersion: "descheduler/v1alpha1"
    kind: "DeschedulerPolicy"
    strategies:
      "RemovePodsViolatingNodeTaints":
        enabled: true
      "RemoveDuplicates":
        enabled: true
      "PodLifeTime":
        enabled: true
        params:
          podLifeTime:
            maxPodLifeTimeSeconds: 120
          labelSelector:
            matchLabels:
              podlifetime: enabled
      "RemovePodsViolatingInterPodAntiAffinity":
        enabled: true
      "RemovePodsViolatingNodeAffinity":
        enabled: true
        params:
          nodeAffinityType:
          - requiredDuringSchedulingIgnoredDuringExecution
      "LowNodeUtilization":
         enabled: true
         params:
           nodeResourceUtilizationThresholds:
             thresholds:
               "cpu" : 20
               "memory": 20
               "pods": 20
             targetThresholds:
               "cpu" : 80
               "memory": 80
               "pods": 80
EOF
```

```bash
kubectl apply -f descheduler-configmap.yaml
```

Verify the deployment by running the below command.

```bash
kubectl get deployment descheduler -n kube-system
```

Output will look like:

{{< output >}}
NAME          READY   UP-TO-DATE   AVAILABLE   AGE
descheduler   1/1     1            1           14s
{{< /output >}}

By default, descheduler is configured to run every 5 minutes. Run the below command to reduce the interval to 2 minutes.

```bash
kubectl patch deployment descheduler -n kube-system --type='json' -p='[{"op": "replace", "path": "/spec/template/spec/containers/0/args", "value": ["--policy-config-file",  "/policy-dir/policy.yaml", "--descheduling-interval", "2m", "--v", "3" ]}]'
```

We will test `RemovePodsViolatingNodeTaints` and `PodLifeTime` policies in the following sections.
