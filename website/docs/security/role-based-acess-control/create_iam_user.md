---
title: "Create a new IAM User"
sidebar_position: 10
---

First of all Let us try to see which IAM identity is configured on the current shell by running following command 
```bash test=false
$ aws sts get-caller-identity
{
    "UserId": "XXXXXXXXXXXXXX:eks-workshop-shell",
    "Account": "XXXXXXXXXX",
    "Arn": "arn:aws:sts::XXXXXXXXXX:assumed-role/eks-workshop-cluster-role/eks-workshop-shell"
}
```
We can see that "eks-workshop-shell" is configured 

Now Let us try to see if the current user have access to see the pods inside carts namespace
```bash test=false
$ kubectl get pods -n carts

NAME                             READY   STATUS    RESTARTS   AGE
carts-789498bdbd-6l8rw           1/1     Running   0          3d22h
carts-dynamodb-cc5bf4649-xccc8   1/1     Running   0          4d
```

Lets now onboard  a new user called carts-user, who needs to have access to carts namespaces. 

Lets generate/save credentials for the user

```bash test=false
$ aws iam create-user --user-name carts-user
$ aws iam create-access-key --user-name carts-user | tee /tmp/create_output.json
```
By running the previous step, you should get a response similar to:

```js
{
    "AccessKey": {
        "UserName": "carts-user",
        "AccessKeyId": < AWS Access Key > ,
        "Status": "Active",
        "SecretAccessKey": < AWS Secret Access Key > ,
        "CreateDate": "2022-10-19T07:33:32+00:00"
    }
}

```
Lets also create a named profile "carts-user" for storing the credentials of new user

```bash test=false
$ aws configure set aws_access_key_id $(jq -r .AccessKey.AccessKeyId /tmp/create_output.json) --profile carts-user && aws configure set aws_secret_access_key $(jq -r .AccessKey.SecretAccessKey /tmp/create_output.json) --profile carts-user && aws configure set region $AWS_DEFAULT_REGION --profile carts-user && aws configure set output "json" --profile carts-user
```
