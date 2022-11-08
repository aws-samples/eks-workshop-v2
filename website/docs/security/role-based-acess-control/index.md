---
title: "Authenticating and Authorizing K8s API with IAM and RBAC"
sidebar_position: 40
---


Role-based access control (RBAC) is a method of regulating access to computer or network resources based on the roles of individual users within an enterprise.

When you create an Amazon EKS cluster, the AWS Identity and Access Management (IAM) entity (user or role) that creates the cluster, is automatically granted system:masters permissions in the cluster's role-based access control (RBAC) configuration in the Amazon EKS control plane. 

The core logical components of RBAC are:

#### Entity
A group, user, or service account (an identity representing an application that wants to execute certain operations (actions) and requires permissions to do so).

#### Resource
A pod, service, or secret that the entity wants to access using the certain operations.

#### Role and ClusterRole
An RBAC Role or ClusterRole contains rules that represent a set of permissions. Permissions are purely additive (there are no "deny" rules).

A Role always sets permissions within a particular namespace; when you create a Role, you have to specify the namespace it belongs in.
ClusterRole, by contrast, is a non-namespaced resource which can be used cluster-wide.
A RoleBinding may reference any Role in the same namespace. 

A RoleBinding can also reference a ClusterRole to grant the permissions defined in that ClusterRole to resources inside the RoleBinding's namespace. This kind of reference lets you define a set of common roles across your cluster, then reuse them within multiple namespaces.
If you want to bind a ClusterRole to all the namespaces in your cluster, you use a ClusterRoleBinding.


#### Role binding and ClusterRoleBinding
A role binding grants the permissions defined in a role to a user or set of users. It holds a list of subjects (users, groups, or service accounts), and a reference to the role being granted. 
A RoleBinding grants permissions within a specific namespace whereas a ClusterRoleBinding grants that access cluster-wide.

#### Namespace
In Kubernetes, namespaces provides a mechanism for isolating groups of resources within a single cluster. 
Names of resources need to be unique within a namespace, but not across namespaces. 
Namespace-based scoping is applicable only for namespaced objects (e.g. Deployments, Services, etc) and not for cluster-wide objects (e.g. StorageClass, Nodes, PersistentVolumes, etc).



In this section we will try to create a new IAM user, map it to Kubernetes and try to explore the above concepts. 
The Objective is to give the new user the access to see all the pods in "carts" namespace

Before we begin let's reset our environment:

```bash timeout=300 wait=30
$ reset-environment 
```
