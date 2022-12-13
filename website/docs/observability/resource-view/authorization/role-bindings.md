---
title: "RoleBindings"
sidebar_position: 44
---

A **[Role binding](https://kubernetes.io/docs/reference/access-authn-authz/rbac/#rolebinding-and-clusterrolebinding)** grants role permissions to a user or set of users. Rolebindings are assigned to a particular namespace during creation. The Rolebinding resource holds a list of subjects (users, groups, or service accounts), and a reference to the role being granted. A **_RoleBinding_** grants permissions within a specific namespace like pods, replicasets, jobs, and deployments. Whereas a **_ClusterRoleBinding_** grants cluster scoped resources like nodes.

Under <i>Resource Type</i> - <i>Authorization</i> section you can view **_ClusterRoleBindings_** and **_Rolebindings_** resources on your cluster listed by namespace. Example  **_RoleBindings_** are shown in the following screenshot.

![Insights](/img/resource-view/autz-rolebinding.jpg)

A **[ClusterRoleBinding](https://kubernetes.io/docs/reference/access-authn-authz/rbac/#rolebinding-and-clusterrolebinding)** attach **_ClusterRoles_** to a set of users. They are scoped to a cluster, and are not bound to namespaces like **_Roles_** and **_RoleBindings_**.

![Insights](/img/resource-view/authz-crolebinding.jpg)
