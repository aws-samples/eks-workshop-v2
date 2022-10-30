---
title: "Test the User access after Role binding"
sidebar_position: 50
---

Now that the user, Role, and RoleBinding are defined, lets switch back to rbac-user, and test.

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
Now we had made sure that the active user is carts-user. Lets try to access the pods inside carts namespace 
```bash test=false
$ kubectl get pods -n carts

NAME                             READY   STATUS    RESTARTS   AGE
carts-789498bdbd-6l8rw           1/1     Running   0          3d23h
carts-dynamodb-cc5bf4649-xccc8   1/1     Running   0          4d1h
```
Voilà.. user carts-user can see the pods now.. Now lets test if he have access to pods inside another namespace orders
```bash test=false
$ kubectl get pods -n orders   

Error from server (Forbidden): pods is forbidden: User "carts-user" cannot list resource "pods" in API group "" in the namespace "orders"
```