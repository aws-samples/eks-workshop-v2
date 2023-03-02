---
title: "Unauthorized creation or tampering of resourses by unauthenticated user" 
sidebar_position: 128
---

This finding is used to indicate that an API commonly used to tamper with resources in a Kubernetes cluster was invoked by an unauthenticated user.

To simulate this we'll create two `role` resources, **pod-create** and **psp-use**.

```bash
$ kubectl create role pod-create --verb=create --resource=pods -n default
$ kubectl create role psp-use --verb=use --resource=podsecuritypolicies -n default
```

Once the `role` is created we'll need to bind it with the `system:anonymous` user. Below command will create `rolebinding` named **pod-access** and **psp-access** binding the `roles` **pod-create** and **psp-use** to the user named `system:anonymous`.

```bash
$ kubectl create rolebinding pod-access --role=pod-create --user=system:anonymous -n default
$ kubectl create rolebinding psp-access --role=psp-use --user=system:anonymous -n default
```

Note that the above rolebinding command will trigger `Policy:Kubernetes/AnonymousAccessGranted` finding in guard duty within few minutes.

Now let us create a Pod named nginx using a HTTP post call. 

```bash
$ API_URL=$(aws eks describe-cluster --name $EKS_CLUSTER_NAME --query "cluster.endpoint" --region $AWS_DEFAULT_REGION --output text)
$ curl -k -v $API_URL/api/v1/namespaces/default/pods -X POST -H 'Content-Type: application/yaml' -d '---
apiVersion: v1
kind: Pod
metadata:
  name: nginx
  namespace: default
spec:
  containers:
  - name: nginx
    image: nginx
    ports:
    - containerPort: 80
'
```

Verify if the Pod is Running.

```bash
$ kubectl get pods -n default

NAME                                 READY   STATUS    RESTARTS   AGE
nginx                                1/1     Running   0          2m17s
```

Within a few minutes we'll see the finding `Impact:Kubernetes/SuccessfulAnonymousAccess` in the GuardDuty portal.

![](impact_SuccessfulAnonymousAccess.png)

Cleanup:

```bash
$ kubectl delete pod nginx -n default
$ kubectl delete rolebinding pod-access psp-access -n default
$ kubectl delete role pod-create psp-use -n default
```
