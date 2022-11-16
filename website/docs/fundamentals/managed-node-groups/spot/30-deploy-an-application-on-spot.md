---
title: Deploy an Application on Spot Instances
sidebar_position: 30
---

You can constrain a Pod so that it is restricted to run on particular node(s), or to prefer to run on particular nodes. 
There are several ways to do this and the recommended approaches all use label selectors to facilitate the selection.

In this section, we will be deploying a nginx server on Spot Instances leveraging on [Node Affinity](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#affinity-and-anti-affinity)

## Deploy the nginx application on Spot instance

First, we will create a manifest file leveraging on Node Affinity to inform the scheduler to try to find a spot instance to deploy the pods

```bash
$ cat <<EOF >> nginx-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
spec:
  selector:
    matchLabels:
      app: nginx
  replicas: 4 # tells deployment to run 4 pods matching the template
  template:
    metadata:
      labels:
        app: nginx
    spec:
      affinity:
        nodeAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 1
            preference:
              matchExpressions:
              - key: eks.amazonaws.com/capacityType
                operator: In
                values:
                - SPOT
      containers:
      - name: nginx
        image: nginx:1.14.2
        ports:
        - containerPort: 80
        
EOF
```

:::info
There are two types of node affinity:

1. **requiredDuringSchedulingIgnoredDuringExecution**: The scheduler can't schedule the Pod unless the rule is met. This functions like nodeSelector, but with a more expressive syntax.
2. **preferredDuringSchedulingIgnoredDuringExecution**: The scheduler tries to find a node that meets the rule. If a matching node is not available, the scheduler still schedules the Pod.
:::

After creating the manifest, we can deploy our nginx application

```bash
$ kubectl apply -f nginx-deployment.yaml
```

## Result 

Verify that all 4 pods are deployed on SPOT instances

```bash
$ for n in $(kubectl get nodes -l eks.amazonaws.com/capacityType=SPOT --no-headers | cut -d " " -f1); \
do echo "=================="; echo "Pods on instance ${n}:";kubectl get pods --no-headers --field-selector spec.nodeName=${n} -l app=nginx; echo ; \
done

==================
Pods on instance ip-10-42-1-16.ap-southeast-1.compute.internal:
nginx-deployment-6d647796c5-lb529   1/1   Running   0     7s
nginx-deployment-6d647796c5-mwr5r   1/1   Running   0     27m

==================
Pods on instance ip-10-42-2-19.ap-southeast-1.compute.internal:
nginx-deployment-6d647796c5-294m2   1/1   Running   0     27m
nginx-deployment-6d647796c5-h8m4d   1/1   Running   0     8s



```

Verify that the pod is **NOT** deployed on ON_DEMAND instances

```bash
$ for n in $(kubectl get nodes -l eks.amazonaws.com/capacityType=ON_DEMAND --no-headers | cut -d " " -f1); \
do echo "=================="; echo "Pods on instance ${n}:";kubectl get pods --no-headers --field-selector spec.nodeName=${n} -l app=nginx; echo ; \
done

==================
Pods on instance ip-10-42-10-228.ap-southeast-1.compute.internal:
No resources found in default namespace.

==================
Pods on instance ip-10-42-10-232.ap-southeast-1.compute.internal:
No resources found in default namespace.

==================
Pods on instance ip-10-42-12-226.ap-southeast-1.compute.internal:
No resources found in default namespace.

```

