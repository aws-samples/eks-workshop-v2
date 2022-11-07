---
title: "Roles"
sidebar_position: 43
---

A **[Role](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)** defines a set of permissions to be applied to a user. Role-based access control (RBAC) is a method of regulating access to computer or network resources based on the roles of individual users within your organization. A Role always sets permissions within a particular namespace, when you create a Role, you have to specify the namespace it belongs in.

![Insights](/img/resource-view/autz-role.jpg)

To have more details about each <i>roles</i> for example in the below screen <i>cluster-autoscaler-aws-cluster-autoscaler</i> is a role created under namespace <i>kube-system</i> which has access like <i>delete</i>, <i>get</i>, <i>update</i> to the resources <i>configmaps</i> .

![Insights](/img/resource-view/autz-role-detail.jpg)

A **[ClusterRoles](https://kubernetes.io/docs/reference/access-authn-authz/rbac/#role-and-clusterrole)** are a set of rules that are do not need to be scoped to a particular namespace, which makes them distinct from an RBAC Role. They are additive, and you cannot set "deny" rules. You would generally use ClusterRoles to define cluster-wide permissions.

![Insights](/img/resource-view/authz-crole.jpg)