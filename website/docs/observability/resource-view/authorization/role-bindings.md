---
title: "RoleBindings"
sidebar_position: 44
---

A **[Role binding](https://kubernetes.io/docs/reference/access-authn-authz/rbac/#rolebinding-and-clusterrolebinding)** grants role permissions to a user or set of users. Rolebindings are assigned to particular namespace during creation, if not, then rolebindings are mapped to default namespace. It holds a list of subjects (users, groups, or service accounts), and a reference to the role being granted. A **<i>RoleBinding</i>** grants permissions within a specific namespace whereas a **_ClusterRoleBinding_** grants cluster scoped resources. For example **_namespaced_** resources like pods, replicasets, jobs, deployments, PVC etc and **_cluster scoped_** resources like nodes, PV etc.

![Insights](/img/resource-view/autz-rolebinding.jpg)

A **[ClusterRoleBinding](https://kubernetes.io/docs/reference/access-authn-authz/rbac/#rolebinding-and-clusterrolebinding)** attach ClusterRoles to a set of users. They work across clusters, and are not bound to namespaces like Roles and RoleBindings.

![Insights](/img/resource-view/authz-crolebinding.jpg)