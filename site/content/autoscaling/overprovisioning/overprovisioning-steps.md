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

## Verify Nodegroup Size

The Cluster's Nodegroup size is tied to ASG. EKS modified ASG's min-size, max-size and desired-capacity to adjust the Nodegroup's size. Check if this value will accommodate your over provisioning needs. The environment is configured with **—-max-size** **`"6"`**.

```bash
# Get the Nodegroup Name
export EKS_NODEGROUP_NAME=$(aws eks list-nodegroups --cluster-name $EKS_CLUSTER_NAME --query "nodegroups[0]" --output text)

# Display the current Nodgroup size configurations
aws eks describe-nodegroup --cluster-name $EKS_CLUSTER_NAME --nodegroup-name $EKS_NODEGROUP_NAME --query nodegroup.scalingConfig --output table
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
   replicas: 3
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
              cpu: "1"
EOF
```

## Application Scaling (TODO - change based on application)

Now let us scale the application and see what happens to the Pause container pods

The following command shows Pause container pods running in 3 nodes (with 1 vCPU requested)

```bash
kubectl get pods -o wide -l run=pause-pods
```

The output should show

{{< output >}}
NAME                          READY   STATUS    RESTARTS   AGE   IP             NODE                                         NOMINATED NODE   READINESS GATES
pause-pods-55f859d945-65zvp   1/1     Running   0          86s   10.42.12.144   ip-10-42-12-235.us-west-2.compute.internal   <none>           <none>
pause-pods-55f859d945-8jmk6   1/1     Running   0          86s   10.42.10.192   ip-10-42-10-8.us-west-2.compute.internal     <none>           <none>
pause-pods-55f859d945-qjnl5   1/1     Running   0          86s   10.42.11.139   ip-10-42-11-184.us-west-2.compute.internal   <none>           <none>
{{< /output >}}

Currently 3 cluster node run 3 pause container pods and node group size is 6 (**—max-size** of ASG is 6), lets create and scale the application *(with a request of .5 CPU*).

```bash
# Create a deployment - (TODO:Change to app - once decided)
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
spec:
  selector:
    matchLabels:
      app: nginx
  replicas: 1
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx
        ports:
        - containerPort: 80
        resources:
          requests:
            cpu: ".5" # vCPU requested
EOF

# Scale the deployment
kubectl scale deployment --replicas=4 nginx
```

When application gets scaled Pause container pods will get evicted and application pods gets deployed immediately. The following command shows that the applications pods have been deployed and Pause container pods have been evicted and are in pending state. 

```bash
kubectl get pods -o wide
```
The output of above command should be similar to this

{{< output >}}
kubectl get pods -o wide
NAME                          READY   STATUS    RESTARTS   AGE   IP             NODE                                         NOMINATED NODE   READINESS GATES
nginx-5db669fcb8-4n7n6        1/1     Running   0          5s    10.42.10.67    ip-10-42-10-109.us-west-2.compute.internal   <none>           <none>
nginx-5db669fcb8-9ssps        1/1     Running   0          5s    10.42.10.221   ip-10-42-10-109.us-west-2.compute.internal   <none>           <none>
nginx-5db669fcb8-dgkd2        1/1     Running   0          5s    10.42.12.167   ip-10-42-12-186.us-west-2.compute.internal   <none>           <none>
nginx-5db669fcb8-fwv7k        1/1     Running   0          77s   10.42.11.215   ip-10-42-11-229.us-west-2.compute.internal   <none>           <none>
pause-pods-5c765d9cb5-27mtr   0/1     Pending   0          4s    <none>         <none>                                       <none>           <none>
pause-pods-5c765d9cb5-9mj4v   1/1     Running   0          45m   10.42.12.113   ip-10-42-12-186.us-west-2.compute.internal   <none>           <none>
pause-pods-5c765d9cb5-bs9rq   1/1     Running   0          15m   10.42.11.27    ip-10-42-11-229.us-west-2.compute.internal   <none>           <none>
{{< /output >}}


Next Cluster Autoscaler will kick in and provision a new worked node (using ASG) and pending Pause container pod will get deployed, this will take a few minutes. You can run the following command to see new node getting created, once the new node is available Pause container pods will be scheduled.

```bash
kubectl get nodes -l workshop-default=yes -o wide
```

## Conclusion

In this workshop we have shown how to over provision your cluster (with Pause container pods) to scale your critical applications immediately and reserve space for future critical applications.
