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

#### Role
Used to define rules for the actions the entity can take on various resources.

#### Role binding
This attaches (binds) a role to an entity, stating that the set of rules define the actions permitted by the attached entity on the specified resources.
There are two types of Roles (Role, ClusterRole) and the respective bindings (RoleBinding, ClusterRoleBinding). 
These differentiate between authorization in a namespace or cluster-wide.

#### Namespace
Namespaces are an excellent way of creating security boundaries, they also provide a unique scope for object names as the ‘namespace’ name implies. 
They are intended to be used in multi-tenant environments to create virtual kubernetes clusters on the same physical cluster.

In this section we will try to create a new IAM user, map it to Kubernetes and try to explore the above concepts. 
The Objective is to give the new user the access to see all the pods in "carts" namespace

Before we begin let's reset our environment:

```bash timeout=300 wait=30
$ reset-environment 
```
