---
title: "Setting up the scenario"
sidebar_position: 51
---

DNS resolution in a cluster can be affected by multiple configuration options, which may disrupt service communications. In this module, we'll simulate common DNS-related issues frequently encountered in EKS clusters.

:::tip Don't open the lab setup script, just execute it
When troubleshooting connectivity and DNS resolution issues in your cluster, you typically won't know the root cause upfront. We recommend **not** examining the setup script, but instead following the lab steps to learn a systematic troubleshooting approach for DNS resolution issues in EKS clusters.
:::

Let's introduce the issues for this module by running the following script:

```bash timeout=180 wait=5
$ bash ~/environment/eks-workshop/modules/troubleshooting/dns/.workshop/lab-setup.sh
Configuration applied successfully!
```

Next, redeploy application pods:

```bash timeout=30 wait=30
$ kubectl delete pod -l app.kubernetes.io/created-by=eks-workshop -l app.kubernetes.io/component=service -A
```

Wait for all pods to be recreated and check the application status. You'll notice some pods fail to reach Ready state, showing multiple restarts with Error or CrashLoopBackOff status:

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

Let's investigate the issue.

When pods fail to start properly, we can use `kubectl describe pod` to check for pod and container provisioning issues.

Examine the events section of the non-ready catalog pod:

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

The events show that while the container starts, the application fails to run properly. Failed readiness probes trigger container restarts.

Check the application logs to understand why the application isn't running:

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

The logs reveal that the application fails to connect to the database due to DNS resolution timeout when trying to resolve the MySQL database service name (catalog-mysql).

You can optionally check logs for other non-ready pods, which will show similar DNS resolution failures.

### Next Steps

In the following sections, we'll explore key troubleshooting steps to identify the root cause of the DNS resolution failure.
