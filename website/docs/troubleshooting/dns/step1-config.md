---
title: "Step 1 - Update cluster configuration"
sidebar_position: 30
---

There are multiple configuration options that can affect DNS resolution in the cluster, and therefore halt service communications. For this scenario, we will apply common issues that we have seen on the field that affect DNS resolution in EKS clusters.

:::tip Don't open the lab setup script, just execute it
When facing connectivity and DNS resolution issues in your cluster, you won't know what is causing the problem. I encourage you to **not** look into the script, and instead follow the steps in this lab to learn a troubleshooting approach that can help you root cause different DNS resolution issues in EKS clusters. 
:::

Let’s run the script below to introduce the issues for this scenario:

```bash timeout=180 wait=5
$ bash ~/environment/eks-workshop/modules/troubleshooting/dns/.workshop/lab-setup.sh
Configuration applied successfully!
```

Then, redeploy application pods:

```bash timeout=30 wait=30
$ kubectl delete pod -l app.kubernetes.io/created-by=eks-workshop -l app.kubernetes.io/component=service -A
```

Now, let’s wait for all pods to be recreated and check the status of our application. You will notice that some pods don’t get to Ready state. In fact, these pods show multiple restarts and status Error or CrashLoopBackOff:
```bash timeout=30 expectError=true
$ kubectl get pod -l app.kubernetes.io/created-by=eks-workshop -l app.kubernetes.io/component=service -A
NAMESPACE   NAME                              READY   STATUS             RESTARTS      AGE
assets      assets-784b5f5656-gtgcg           1/1     Running            0             110s
carts       carts-5475469b7c-gm7kw            0/1     Running            2 (40s ago)   110s
catalog     catalog-5578f9649b-bbrjp          0/1     CrashLoopBackOff   3 (42s ago)   110s
checkout    checkout-84c6769ddd-rvwnv         1/1     Running            0             110s
orders      orders-6d74499d87-lhgwh           0/1     Running            2 (44s ago)   110s
ui          ui-5f4d85f85f-hdhjg               1/1     Running            0             109s
```

There is some problem preventing pods from starting normally.

Let’s investigate what is happening.

When pods are not starting properly, we can describe the pod to know whether there is a problem provisioning the pod and container. 

Describe the catalog pod which is not ready and analyze the Events section:
```bash timeout=30 expectError=true
$ kubectl describe pod -l app.kubernetes.io/name=catalog -l app.kubernetes.io/component=service -n catalog
...
Events:
  Type     Reason     Age                    From               Message
  ----     ------     ----                   ----               -------
  Normal   Scheduled  3m47s                  default-scheduler  Successfully assigned catalog/catalog-5578f9649b-bbrjp to ip-10-42-100-65.us-west-2.compute.internal
  Normal   Started    3m16s (x3 over 3m46s)  kubelet            Started container catalog
  Warning  Unhealthy  3m12s (x9 over 3m46s)  kubelet            Readiness probe failed: Get "http://10.42.115.209:8080/health": dial tcp 10.42.115.209:8080: connect: connection refused
  Warning  BackOff    2m55s (x5 over 3m34s)  kubelet            Back-off restarting failed container catalog in pod catalog-5578f9649b-bbrjp_catalog(b5c1c1fa-5db6-4be4-8dcd-0910410f5630)
  Normal   Pulled     2m44s (x4 over 3m46s)  kubelet            Container image "public.ecr.aws/aws-containers/retail-store-sample-catalog:0.4.0" already present on machine
  Normal   Created    2m44s (x4 over 3m46s)  kubelet            Created container catalog
```

Pod events show that the container is started but then the application inside the container is not running properly. The readiness probe fails, causing Kubernetes to restart the container.

Next, we need to check application logs inside this pod to discover why the application is not running properly:
```bash timeout=30 expectError=true
$ kubectl logs -l app.kubernetes.io/name=catalog -l app.kubernetes.io/component=service -n catalog
2024/10/20 15:19:27 Running database migration...
2024/10/20 15:19:27 Schema migration applied
2024/10/20 15:19:27 Connecting to catalog-mysql:3306/catalog?timeout=5s
2024/10/20 15:19:27 invalid connection config: missing required peer IP or hostname
2024/10/20 15:19:27 Connected
2024/10/20 15:19:27 Connecting to catalog-mysql:3306/catalog?timeout=5s
2024/10/20 15:19:27 invalid connection config: missing required peer IP or hostname
2024/10/20 15:19:32 Error: Unable to connect to reader database dial tcp: lookup catalog-mysql: i/o timeout
2024/10/20 15:19:32 dial tcp: lookup catalog-mysql: i/o timeout
```

Application logs show that during the execution, the application tries to connect to the database, but this connection fails due to timeout resolving the name of the MySQL database service, as we can see in the error line `dial tcp: lookup catalog-mysql: i/o timeout`

Now we know that DNS resolution is not working for this pod.

Optionally, you can check application logs for other pods that are not ready. There will be similar connection errors caused by failed DNS resolution.

In the following sections, we will cover some important troubleshooting steps that will help us identify why DNS resoultion is not working.
