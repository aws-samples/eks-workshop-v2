---
title: "Cleanup"
sidebar_position: 60
---

Its time to cleanup the cluster to previous stage. Execute following commands
```bash test=false
$ unset AWS_ACCESS_KEY_ID  
$ unset AWS_SECRET_ACCESS_KEY  
$ unset AWS_PROFILE  
$ rm rbacuser_creds.sh
$ rm rbacuser-role.yaml
$ rm rbacuser-role-binding.yaml
$ aws iam delete-access-key --user-name=rbac-user --access-key-id=$(jq -r .AccessKey.AccessKeyId /tmp/create_output.json)
$ aws iam delete-user --user-name rbac-user
$ rm /tmp/create_output.json
```
Next remove the rbac-user mapping from the existing configMap by editing the existing aws-auth.yaml file from 
```js
data:
  mapUsers: |
    - userarn: arn:aws:iam::${ACCOUNT_ID}:user/carts-user
      username: carts-user

```
to 
```js
data:
  mapUsers: |
    []
```

Next, apply the ConfigMap to apply this mapping to the system:

```bash test=false
$ kubectl apply -f aws-auth.yaml
```
