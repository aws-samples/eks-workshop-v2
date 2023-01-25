---
title: "Roles"
sidebar_position: 43
---

A **[Role](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)** defines a set of permissions to be applied to a user. Role-based access control (RBAC) is a method of regulating access to computer or network resources based on the roles of individual users within your organization. A Role always sets permissions within a particular namespace, when you create a Role, you have to specify the namespace it belongs in. 

Under **_Resource Type_** - **_Authorization_** section you can view **_ClusterRoles_** and **_Roles_** resources on your cluster listed by namespace.

![Insights](/img/resource-view/autz-role.jpg)

Click on the **_cluster-autoscaler-aws-cluster-autoscaler_** role to view more details for that **_role_**. The below screenshot shows the **_cluster-autoscaler-aws-cluster-autoscaler_** role created under namespace **_kube-system_** which has authorization to **_delete_**, **_get_**, and **_update_** on **_configmaps_** resources.

![Insights](/img/resource-view/autz-role-detail.jpg)

A **[ClusterRoles](https://kubernetes.io/docs/reference/access-authn-authz/rbac/#role-and-clusterrole)** are a set of rules that are scoped to a cluster and not a namespace, which makes them different from a **_Role_**. **_ClusterRoles_** are additive, and you cannot set "deny" rules. You would generally use **_ClusterRoles_** to define cluster-wide permissions. Below we can see the list of **_ClusterRoles_** on your cluster. 

![Insights](/img/resource-view/authz-crole.jpg)
