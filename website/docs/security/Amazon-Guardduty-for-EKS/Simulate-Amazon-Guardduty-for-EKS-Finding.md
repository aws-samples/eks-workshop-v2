---
title: "Simulate Amazon Guardduty for EKS Findings"
sidebar_position: 65
---

In this section, we will generate various Kubernetes findings in your Amazon EKS cluster.  


**Discovery:Kubernetes/SuccessfulAnonymousAccess**

This finding is used to indicate Kubernetes API commonly used in Discovery tactics by the anonymous user system:anonymous.

We will need to create a cluster role binding to bind **view** permissions to **system:anonymous** user.

```bash
$ kubectl create clusterrolebinding anonymous-view --clusterrole=view --user=system:anonymous
```

Identify the API server url of the cluster.
```bash
$ API_URL=`aws eks describe-cluster --name <cluster-name> --query "cluster.endpoint" --region us-east-1 --output text`
$ curl -k $API_URL/api/v1/pods
```

With in few minutes we will see the finding `Discovery:Kubernetes/SuccessfulAnonymousAccess` in guardduty portal. 

![](finding-1.png)

Run the following command to delete the cluster role binding.

```bash
$ kubectl delete clusterrolebinding anonymous-view
```


**Impact:Kubernetes/SuccessfulAnonymousAccess and Policy:Kubernetes/AnonymousAccessGranted**
This finding is used to indicate that A API commonly used to tamper with resources in a Kubernetes cluster was invoked by an unauthenticated user.

To simulate this we will need to first create a role **pod-create**. 
```bash
$ kubectl create role pod-create --verb=get,list,watch,create,delete,patch --resource=pods -n default
```
Once the cluster role is created we will need to bind the role with **system:anonymous** user. Below command will create rolebinding named pod-access binding role pod-create to the user named system:anonymous.

```bash
$ kubectl create rolebinding pod-access --role=pod-create --user=system:anonymous
```
Please note that the above rolebinding command will trigger `Policy:Kubernetes/AnonymousAccessGranted` finding in guard duty within few minutes. 

Now let us create a pod named nginx using a HTTP post call. 

```bash
$ API_URL=`aws eks describe-cluster --name <cluster-name> --query "cluster.endpoint" --region us-east-1 --output text`
$ curl -k -v  $API_URL/api/v1/namespaces/default/pods -X POST -H 'Content-Type: application/yaml'   -d '---
apiVersion: v1
kind: Pod
metadata:
  name: nginx
  namespace: default
spec:
  containers:
  - name: nginx
    image: nginx:1.14.2
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
![](finding-3.png)


Cleanup: 
```bash
kubectl delete pod nginx -n default
kubectl delete rolebinding pod-access -n default
kubectl delete role pod-create -n default
```

**Policy:Kubernetes/AdminAccessToDefaultServiceAccount**

The default service account in EKS Cluster was granted admin privileges. This may result in pods unintentionally launched with admin privileges. If this behavior is not expected, it may indicate a configuration mistake or that your credentials are compromised.

```bash
$ kubectl create rolebinding sa-default-admin --clusterrole=cluster-admin --serviceaccount=default:default --namespace=default
```
With in few minutes we will see the finding `Policy:Kubernetes/AdminAccessToDefaultServiceAccount` in guardduty portal. 

![](finding-2.png)

Run the following command to delete the role binding.

```bash
$ kubectl delete rolebinding sa-default-admin --namespace=default
```

**Policy:Kubernetes/ExposedDashboard**

This finding informs you that Kubernetes dashboard for your cluster was exposed to the internet by a Load Balancer service. An exposed dashboard makes the management interface of your cluster accessible from the internet and allows adversaries to exploit any authentication and access control gaps that may be present.




**PrivilegeEscalation:Kubernetes/PrivilegedContainer and Persistence:Kubernetes/ContainerWithSensitiveMount**
  