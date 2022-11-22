---
title: "Verify the logs in CloudWatch"
sidebar_position: 40
---

In this section, we will see how to checks theKubernetespod logs forwarded by the Fluent-bit agent deployed on each node to Amazon CloudWatch logs. The deployed application components write logs to `stdout`, which are saved in the `/var/log/containers/*.log` path on each node. Verify the resources deployed in **_assets_** namespace and pod logs using the below commands.

```bash
$ kubectl get all -n assets
NAME                         READY   STATUS    RESTARTS   AGE
pod/assets-ddb8f87dc-z4qnt   1/1     Running   0          3d19h

NAME             TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
service/assets   ClusterIP   172.20.228.20   <none>        80/TCP    3d19h

NAME                     READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/assets   1/1     1            1           3d19h

NAME                               DESIRED   CURRENT   READY   AGE
replicaset.apps/assets-ddb8f87dc   1         1         1       3d19h
```

```bash
$ kubectl logs -n assets deployment/assets 
10.42.12.195 - - [30/Oct/2022:23:18:10 +0000] "GET /health.html HTTP/1.1" 200 2 "-" "kube-probe/1.23+" "-"
10.42.12.195 - - [30/Oct/2022:23:18:13 +0000] "GET /health.html HTTP/1.1" 200 2 "-" "kube-probe/1.23+" "-"
10.42.12.195 - - [30/Oct/2022:23:18:16 +0000] "GET /health.html HTTP/1.1" 200 2 "-" "kube-probe/1.23+" "-"
10.42.12.195 - - [30/Oct/2022:23:18:19 +0000] "GET /health.html HTTP/1.1" 200 2 "-" "kube-probe/1.23+" "-"
10.42.12.195 - - [30/Oct/2022:23:18:22 +0000] "GET /health.html HTTP/1.1" 200 2 "-" "kube-probe/1.23+" "-"
10.42.12.195 - - [30/Oct/2022:23:18:25 +0000] "GET /health.html HTTP/1.1" 200 2 "-" "kube-probe/1.23+" "-"
10.42.12.195 - - [30/Oct/2022:23:18:28 +0000] "GET /health.html HTTP/1.1" 200 2 "-" "kube-probe/1.23+" "-"
10.42.12.195 - - [30/Oct/2022:23:18:31 +0000] "GET /health.html HTTP/1.1" 200 2 "-" "kube-probe/1.23+" "-"
10.42.12.195 - - [30/Oct/2022:23:18:34 +0000] "GET /health.html HTTP/1.1" 200 2 "-" "kube-probe/1.23+" "-"
10.42.12.195 - - [30/Oct/2022:23:18:37 +0000] "GET /health.html HTTP/1.1" 200 2 "-" "kube-probe/1.23+" "-"
```

2. The Fluent-bit daemonset setup from the previous section is configured to stream the logs saved in _/var/log/containers/*.log_ from each node to CloudWatch log group _/eks-workshop-cluster/worker-fluentbit-logs_

    a. To verify the logs in Amazon CloudWatch, login to **CloudWatch console** -> Select **Logs** dropdown from the left navigation pane -> **Logs groups** -> filter for _/eks-workshop-cluster/worker-fluentbit-logs_

    ![CWLogs](/img/observability-logging/logging-cw-console.png)

    b. Filter for 'assets' to check the pods logs deployed in the **_assets_** namespace and then click the log stream name.

    ![Podlogs](/img/observability-logging/logging-cw-pod-logs.png)

    ![AssetPodlogs](/img/observability-logging/logging-cw-asset-pod-logs.png)



