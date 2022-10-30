---
title: "Create the Role and RoleBinding"
sidebar_position: 40
---

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
