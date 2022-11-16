---
title: "unauthorized creation or tampering of resourses by unauthenticated user" 
sidebar_position: 128
---

This finding is used to indicate that an API commonly used to tamper with resources in a Kubernetes cluster was invoked by an unauthenticated user.

To simulate this we will create a role **pod-create** and **psp-use**.

```bash
$ kubectl create role pod-create --verb=create --resource=pods -n default
$ kubectl create role psp-use --verb=use --resource=podsecuritypolicies -n default
```

Once the role is created we will need to bind the role with `system:anonymous` user. Below command will create rolebinding named `pod-access` and `psp-access` binding roles `pod-create` and `psp-use` to the user named `system:anonymous`.

```bash
$ kubectl create rolebinding pod-access --role=pod-create --user=system:anonymous -n default
$ kubectl create rolebinding psp-access --role=psp-use --user=system:anonymous -n default
```

Please note that the above rolebinding command will trigger `Policy:Kubernetes/AnonymousAccessGranted` finding in guard duty within few minutes.

Now let us create a pod named nginx using a HTTP post call. Please make sure to replace `eks-workshop-cluster` with your **cluster name** with your cluster name and `REGION` with your region.

```bash
$ API_URL=`aws eks describe-cluster --name eks-workshop-cluster --query "cluster.endpoint" --region <REGION> --output text`
$ curl -k -v  $API_URL/api/v1/namespaces/default/pods -X POST -H 'Content-Type: application/yaml'   -d '---
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

verify if the pod is created.

```bash
$ kubectl get pods -n default

NAME                                 READY   STATUS    RESTARTS   AGE
nginx                                1/1     Running   0          2m17s
```

With in few minutes we will see the finding `Impact:Kubernetes/SuccessfulAnonymousAccess` in guardduty portal.

![](impact_SuccessfulAnonymousAccess.png)

Cleanup:

```bash
$ kubectl delete pod nginx -n default
$ kubectl delete rolebinding pod-access psp-access -n default
$ kubectl delete role pod-create psp-use -n default
```
