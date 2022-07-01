---
title: "Configure Over Provisioning with CA"
weight: 35
chapter: false
---

## Create Default Priority Class 

It is best practice to create appropriate PriorityClass for your applications. Create **global default priority class** using the field **`globalDefault:true`**. This default PriorityClass will be assigned pods/deployments that don’t specify a `PriorityClassName`.

```bash
# Create the PriorityClass for all pods in cluster (Global Default)
cat <<EOF | kubectl apply -f -
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
   name: default
value: 0
globalDefault: true
description: "Default Priority class."
EOF
```

## Create Over provisioning Pod’s Priority Class

Next create PriorityClass that will be assigned to Pause Container pods used for over provisioning with priority value **"-1"**.

```bash

# Create the PriorityClass for overprovisioned pause container 
cat <<EOF | kubectl apply -f -
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
   name: pause-pods
value: -1
globalDefault: false
description: "Priority class used by pause-pods for overprovisioning."
EOF
```

Verify priority classes using the command (output shows system default priority classes as well).

```bash
kubectl get priorityclass
```

The output will show the PriortyClass created with appropriate values

{{< output >}}
NAME                      VALUE        GLOBAL-DEFAULT   AGE
default                   0            true             82s
pause-pods                -1           false            9s
system-cluster-critical   2000000000   false            17d
{{< /output >}}

## Configure CA to include best-effort pods for Scaling

Patch CA to set flag **`expendable-pods-priority-cutoff`** to value **`-10`** so Pause pods are taken into consideration when Cluster Autoscaler does the scaling operation.

```bash
# Patch the Cluster Autoscaler so it takes expendable pod into account for making scaling decisions
kubectl patch deployment cluster-autoscaler-aws-cluster-autoscaler -n kube-system \
-p '{"spec": {"template": {"spec": {"containers": [{"name": "aws-cluster-autoscaler","command": ["./cluster-autoscaler","--v=4","--stderrthreshold=info","--cloud-provider=aws","--skip-nodes-with-local-storage=false","--expander=least-waste","--node-group-auto-discovery=asg:tag=k8s.io/cluster-autoscaler/enabled,k8s.io/cluster-autoscaler/eksworkshop-eksctl","--balance-similar-node-groups","--skip-nodes-with-system-pods=false","--expendable-pods-priority-cutoff=-10"]}]}}}}'
```

## Configure AWS AutoScaling Group (ASG)

Configure ASG’s max-size to be a value that will accommodate your over provisioning needs. Here we are configuring **—-max-size** to 4 and the current cluster has 3 nodes (***--desired-capacity 3***).

```bash

# Get Cluster Name
export EKS_CLUSTER_NAME=$(aws eks list-clusters --query "clusters[0]" --output text)

# Get ASG name
export ASG_NAME=$(aws autoscaling describe-auto-scaling-groups --query "AutoScalingGroups[? Tags[? (Key=='eks:cluster-name') && Value=='$EKS_CLUSTER_NAME']].AutoScalingGroupName" --output text)

# increase max capacity up to 4
aws autoscaling \
    update-auto-scaling-group \
    --auto-scaling-group-name ${ASG_NAME} \
    --min-size 3 \
    --desired-capacity 3 \
    --max-size 4

# Check new values
aws autoscaling \
    describe-auto-scaling-groups \
    --query "AutoScalingGroups[? Tags[? (Key=='eks:cluster-name') && Value=='$EKS_CLUSTER_NAME']].[AutoScalingGroupName, MinSize, MaxSize,DesiredCapacity]" \
    --output table
```

## Create Over provisioning Pause container deployment

Create pause containers to make sure there are enough nodes that are available based on how much over provisioning is needed for your environment. Keep in mind the `—max-size` parameter in ASG (of EKS node group). Cluster Autoscaler won’t increase number of nodes beyond this maximum specified in the ASG

```bash
# Create deployment for Pause Container pods
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
   name: pause-pods
   namespace: default
spec:
   replicas: 2
   selector:
      matchLabels:
        run: pause-pods
   template:
      metadata:
        labels:
          run: pause-pods
      spec:
        priorityClassName: pause-pods
        containers:
        - name: reserve-resources
          image: k8s.gcr.io/pause
          resources:
            requests:
              cpu: "1.5"
              memory: "1G"
EOF
```

## Application Scaling (TODO - change based on application)

The following command shows the Pause container pods running in 2 nodes

```bash
kubectl get pods -o wide -l run=pause-pods
```

The output should show

{{< output >}}
NAME                          READY   STATUS    RESTARTS   AGE     IP               NODE                                          NOMINATED NODE   READINESS GATES
pause-pods-5c765d9cb5-h87hj   1/1     Running   0          7m35s   192.168.56.218   ip-192-168-63-47.us-west-2.compute.internal   <none>           <none>
pause-pods-5c765d9cb5-nxspd   1/1     Running   0          4h36m   192.168.68.232   ip-192-168-86-79.us-west-2.compute.internal   <none>           <none>
{{< /output >}}

Currently 3rd cluster node is running pause container pod and there **—max-size** of the ASG is 4, lets scale up the application.

```bash
# Create a deployment - (TODO:Change to app - once decided)
kubectl create deployment nginx --image=nginx

# Scale the deployment
kubectl scale deployment --replicas=17 nginx
```


The following command shows that the applications pods have been deployed and Pause container pods have been evicted and are in pending state. Next Cluster Autoscaler will kick in and provision a new worked node (using the ASG) and pending Pause container pod will get deployed, this will take a few minutes.

```bash
kubectl get pods
```
The output of the above command should be similar to this

{{< output >}}
NAME                            READY   STATUS    RESTARTS   AGE
kube-ops-view-894bc75fb-gcw9b   1/1     Running   0          42h
nginx-6799fc88d8-2srf4          1/1     Running   0          59s
nginx-6799fc88d8-48c66          1/1     Running   0          32s
nginx-6799fc88d8-5vbfp          1/1     Running   0          59s
nginx-6799fc88d8-62xh4          1/1     Running   0          47s
nginx-6799fc88d8-67hsk          1/1     Running   0          59s
nginx-6799fc88d8-8nqjs          1/1     Running   0          59s
nginx-6799fc88d8-b988b          1/1     Running   0          32s
nginx-6799fc88d8-cfn96          1/1     Running   0          59s
nginx-6799fc88d8-d7vcp          1/1     Running   0          32s
nginx-6799fc88d8-hnkdm          1/1     Running   0          4h51m
nginx-6799fc88d8-hnkjb          1/1     Running   0          32s
nginx-6799fc88d8-jhbbt          1/1     Running   0          60s
nginx-6799fc88d8-lc69l          1/1     Running   0          47s
nginx-6799fc88d8-pkq92          1/1     Running   0          59s
nginx-6799fc88d8-pqz47          1/1     Running   0          59s
nginx-6799fc88d8-q2t5r          1/1     Running   0          60s
pause-pods-5c765d9cb5-6c82d     0/1     Pending   0          32s
pause-pods-5c765d9cb5-smnfl     0/1     Pending   0          32s
{{< /output >}}


You can run the following command to see new node getting created, once the new node is available Pause container pods will be scheduled.

```bash
kubectl get nodes -o wide
```

## Conclusion
In this workshop we have shown how to over provision your cluster to scale your critical applications immediately.
