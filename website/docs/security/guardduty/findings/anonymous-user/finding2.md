---
title: "Discovery tacitc to access theKubernetesAPI Anonymously"
sidebar_position: 127
---

This finding is used to indicate Kubernetes API commonly used to gain knowledge about the resources has been invoked by an anonymous user `system:anonymous`.

To simulate this we'll need to create a cluster role binding to bind clusterrole named **view** to user named **system:anonymous**.

```bash
$ kubectl create clusterrolebinding anonymous-view --clusterrole=view --user=system:anonymous
```

Note that the above rolebinding command will trigger `Policy:Kubernetes/AnonymousAccessGranted` finding in guard duty within few minutes.

Identify the API server url of the cluster and run a http get call for uri /api/v1/pods using curl. This is equivalent to running `kubectl get pods -A -o json`. The difference between kubectl and curl is that while using kubectl we'll be attaching an auth bearer token to authenticate however while running curl we're not using any auth bearer token and skipping authentication and using `system:anonymous` for authorization.

Make sure to replace `eks-workshop` with your cluster name and `REGION` with your region.

```bash
$ API_URL=`aws eks describe-cluster --name eks-workshop --query "cluster.endpoint" --region <REGION> --output text`
$ curl -k $API_URL/api/v1/pods
```

Within a few minutes we'll see the finding `Discovery:Kubernetes/SuccessfulAnonymousAccess` in the GuardDuty portal.

![](discovery_SuccessfulAnonymousAccess.png)

Run the following command to delete the cluster role binding.

```bash
$ kubectl delete clusterrolebinding anonymous-view
```
