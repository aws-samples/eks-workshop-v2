---
title: "Test the User access after Role binding"
sidebar_position: 50
---

Now that the user, Role, and RoleBinding are defined, let's switch back to rbac-user, and test.

To switch back to rbac-user, issue the following commands

```bash test=false
$ export AWS_PROFILE=carts-user
$ export AWS_SECRET_ACCESS_KEY=$(jq -r .AccessKey.SecretAccessKey /tmp/create_output.json)
$ export AWS_ACCESS_KEY_ID=$(jq -r .AccessKey.AccessKeyId /tmp/create_output.json)
```
Verify that current user contect belongs to user - carts-user
```bash test=false
$ aws sts get-caller-identity

{
    "UserId": "<User Id>",
    "Account": "<ACCOUNT_ID>",
    "Arn": "arn:aws:iam::<ACCOUNT_ID>:user/carts-user"
}
```
Now we had made sure that the active user is carts-user. Let's try to access the pods inside carts namespace 
```bash test=false
$ kubectl auth can-i get pods -n carts

yes
```
User carts-user can see the pods now. Now let's test if they have access to pods inside another namespace orders
```bash test=false
$ kubectl auth can-i get pods -n orders   

no
```
AS expected user - carts-user doesn't have access to see pods inside orders namespace