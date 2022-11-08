---
title: "Map IAM User to Kubernetes"
sidebar_position: 20
---

Let's define a kubernetes user called carts-user, and map to its IAM user counterpart.

To grant additional AWS users or roles the ability to interact with your cluster, you must update the aws-auth ConfigMap within Kubernetes

Run the following to describe the existing ConfigMap.

```bash test=false
$ kubectl describe configmap -n kube-system aws-auth
```
You can see that the mapUsers section doesn't have any value currently

```js
mapUsers:
----
[]
```

Now let's update the aws-auth configmap. An improperly formatted aws-auth ConfigMap may cause you to lose access to the cluster. 
Hence we need to make changes to the ConfigMap, using tools like [eksctl](https://eksctl.io/usage/iam-identity-mappings/) or [aws-auth](https://github.com/keikoproj/aws-auth)
Since eksctl is already installed in this setup we will use eksctl to map the carts-user tp aws-auth configmap 

```bash test=false
$ eksctl create iamidentitymapping --cluster  eks-workshop-cluster --region=<AWS_DEFAULT_REGION> --arn arn:aws:iam::<ACCOUNT_ID>:user/carts-user --username carts-user
```
make sure that the actual value of <ACCOUNT_ID> is replaced with ${ACCOUNT_ID} and <AWS_DEFAULT_REGION> should be replaced with ${AWS_DEFAULT_REGION}


Now verify that the user - carts-user is mapped to the aws-auth configmap

```bash test=false
$ kubectl describe configmap -n kube-system aws-auth
```
Check the mapUsers section, you can see that the carts-user is mapped 

```js
mapUsers:
----
- userarn: arn:aws:iam::136514651943:user/carts-user
  username: carts-user
```