---
title: "Role-based access control (RBAC)"
sidebar_position: 40
---


Role-based access control (RBAC) is a method of regulating access to computer or network resources based on the roles of individual users within an enterprise.

When you create an Amazon EKS cluster, the AWS Identity and Access Management (IAM) entity user or role, such as a federated user that creates the cluster, is automatically granted system:masters permissions in the cluster's role-based access control (RBAC) configuration in the Amazon EKS control plane. 

First of all Let us try to see if the current user have access to see the pods inside carts namespace
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

Next, we’ll define a kubernets user called carts-user, and map to its IAM user counterpart.

To grant additional AWS users or roles the ability to interact with your cluster, you must update the aws-auth ConfigMap within Kubernetes

Run the following to get the existing ConfigMap and save into a file called aws-auth.yaml:

```bash test=false
$ kubectl get configmap -n kube-system aws-auth -o yaml | grep -v "creationTimestamp\|resourceVersion\|selfLink\|uid" | sed '/^  annotations:/,+2 d' > aws-auth.yaml

```

Next update 'mapUsers' section of aws-auth.yaml from

```js
data:
  mapUsers: |
    []
```
to

```js
data:
  mapUsers: |
    - userarn: arn:aws:iam::${ACCOUNT_ID}:user/carts-user
      username: carts-user

```
make sure that the actual value of ACCOUNT_ID is replaced with ${ACCOUNT_ID}


Next, apply the ConfigMap to apply this mapping to the system:

```bash test=false
$ kubectl apply -f aws-auth.yaml
```
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

The core logical components of RBAC are:

#### Entity
A group, user, or service account (an identity representing an application that wants to execute certain operations (actions) and requires permissions to do so).

#### Resource
A pod, service, or secret that the entity wants to access using the certain operations.

#### Role
Used to define rules for the actions the entity can take on various resources.

#### Role binding
This attaches (binds) a role to an entity, stating that the set of rules define the actions permitted by the attached entity on the specified resources.
There are two types of Roles (Role, ClusterRole) and the respective bindings (RoleBinding, ClusterRoleBinding). 
These differentiate between authorization in a namespace or cluster-wide.

#### Namespace
Namespaces are an excellent way of creating security boundaries, they also provide a unique scope for object names as the ‘namespace’ name implies. 
They are intended to be used in multi-tenant environments to create virtual kubernetes clusters on the same physical cluster.

Lets to add Roles and Role Bindings to our user carts-user
As mentioned earlier, we have our new user carts-user, but its not yet bound to any roles. In order to do that, we’ll need to switch back to our default admin user.

Run the following to unset the environmental variables that define us as rbac-user:
```bash test=false
$ unset AWS_SECRET_ACCESS_KEY
$ unset AWS_ACCESS_KEY_ID
$ unset AWS_PROFILE 
```
To verify we’re the admin user again, and no longer rbac-user, issue the following command:
```bash test=false
aws sts get-caller-identity

{
    "UserId": "<USER ID>,
    "Account": "<ACCOUNT_ID>",
    "Arn": "arn:aws:sts::<ACCOUNT_ID>:assumed-role/eksworkshop-admin-v2/i-06c4d1fe46764ee5f"
}
```
Now that we’re the admin user again, we’ll create a role called pod-reader that provides list, get, and watch access for pods and deployments, but only for the carts namespace. 
Run the following to create this role:
```bash test=false
$ cat << EoF > rbacuser-role.yaml
kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  namespace: carts
  name: pod-reader
rules:
- apiGroups: [""] # "" indicates the core API group
  resources: ["pods"]
  verbs: ["list","get","watch"]
- apiGroups: ["extensions","apps"]
  resources: ["deployments"]
  verbs: ["get", "list", "watch"]
EoF
```
We have the user, we have the role, and now we’re bind them together with a RoleBinding resource. Run the following to create this RoleBinding:

```bash test=false
$ cat << EoF > rbacuser-role-binding.yaml
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: read-pods
  namespace: rbac-test
subjects:
- kind: User
  name: carts-user
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
EoF
```
Next, we apply the Role, and RoleBindings we created:
```bash test=false
$ kubectl apply -f rbacuser-role.yaml
$ kubectl apply -f rbacuser-role-binding.yaml
```
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
