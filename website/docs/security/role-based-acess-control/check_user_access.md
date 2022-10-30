---
title: "Check the Access of New User"
sidebar_position: 30
---

Up until now, as the cluster operator, you’ve been accessing the cluster as the admin user. 
Let’s now see what happens when we access the cluster as the newly created rbac-user.

Set following environmental variables to switch the context
```bash test=false
$ unset AWS_SESSION_TOKEN
$ export AWS_PROFILE=carts-user
$ export AWS_SECRET_ACCESS_KEY=$(jq -r .AccessKey.SecretAccessKey /tmp/create_output.json)
$ export AWS_ACCESS_KEY_ID=$(jq -r .AccessKey.AccessKeyId /tmp/create_output.json)
```
AWS_SESSION_TOKEN holds the session token specific to current session. since we need to login as carts-user we will unset this varible
AWS_PROFILE decides, which profile is currently active. For our case its carts-user
we will update AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY specific to carts-user

Now lets test if the user context switch is worked or not
```bash test=false
$ aws sts get-caller-identity

{
    "UserId": "<User Id>",
    "Account": "<ACCOUNT_ID>",
    "Arn": "arn:aws:iam::<ACCOUNT_ID>:user/carts-user"
}
```
You can see that the current active user us carts-user

Lets try to see if we are able to see the pods inside carts namespace

```bash test=false
$ kubectl get pods -n carts 

Error from server (Forbidden): pods is forbidden: User "carts-user" cannot list resource "pods" in API group "" in the namespace "carts"
```
We already created the carts-user and mapped to aws_auth config map, so why did we get that error?

Just creating the user doesn’t give that user access to any resources in the cluster. In order to achieve that, we’ll need to define a role, and then bind the user to that role. 
