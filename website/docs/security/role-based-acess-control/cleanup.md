---
title: "Cleanup"
sidebar_position: 60
---

Its time to cleanup the cluster to previous stage. Execute following commands
```bash test=false
$ unset AWS_ACCESS_KEY_ID  
$ unset AWS_SECRET_ACCESS_KEY  
$ unset AWS_PROFILE  
$ rm rbacuser-role.yaml
$ rm rbacuser-role-binding.yaml
$ aws iam delete-access-key --user-name=carts-user --access-key-id=$(jq -r .AccessKey.AccessKeyId /tmp/create_output.json)
$ aws iam delete-user --user-name carts-user
$ rm /tmp/create_output.json
```
Next remove the rbac-user mapping from the existing configMap by editing the existing aws-auth.yaml file from 


```bash test=false
$ eksctl delete iamidentitymapping --cluster  eks-workshop-cluster --region=<AWS_DEFAULT_REGION> --arn arn:aws:iam::<ACCOUNT_ID>:user/carts-user1
```
make sure that the actual value of <ACCOUNT_ID> is replaced with ${ACCOUNT_ID} and <AWS_DEFAULT_REGION> should be replaced with ${AWS_DEFAULT_REGION}


Now verify that the user - carts-user is removed from the aws-auth configmap

```bash test=false
$ kubectl describe configmap -n kube-system aws-auth
```
Check the mapUsers section, you can see that the carts-user is removed

```js
mapUsers:
----
[]
```