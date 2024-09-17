---
title: "Authentication and Authorization"
sidebar_position: 50
---

Click on the **<i>Authentication</i>** tab to drill down to the <i>ServiceAccounts</i> section and you can view Kubernetes service account resources by namespace.

:::info
Check out the [Security](../../../security/) module for additional examples.
:::
A [ServiceAccount](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/) provides an identity for processes that run in a Pod. When you create a pod, if you do not specify a service account, it is automatically assigned the default service account in the same namespace.

![Insights](/img/resource-view/auth-resources.jpg)

To view additional details for a specific <i>service account</i>, drill down to the namespace and click on the service account you want to view to see additional information such as <i>labels</i>, <i>annotations</i>, <i>events</i>. Below is the detail view for the <i>catalog</i> service account.

In EKS, you must be **<i>authenticated</i>** (logged in) before your request can be <i>authorized</i> (granted permission to access). Kubernetes expects attributes that are common to REST API requests. This means that EKS authorization works with [AWS Identity and Access Management](https://docs.aws.amazon.com/eks/latest/userguide/security-iam.html) for access control.

In this lab, we'll view Kubernetes **Role Based Access Control (RBAC)** resources: Cluster Roles, Roles, ClusterRoleBindings and RoleBindings. RBAC is the process of providing restricted least privileged access to EKS clusters and its objects as per the IAM roles mapped to the EKS cluster users. Following diagram depicts how the access control flows when users or service accounts try to access the objects in EKS cluster through the Kubernetes client and API's.

:::info
Check out the [Security](../../../security/) module for additional examples.
:::

![Insights](/img/resource-view/autz-index.jpg)

A **[Role](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)** defines a set of permissions to be applied to a user. Role-based access control (RBAC) is a method of regulating access to computer or network resources based on the roles of individual users within your organization. A Role always sets permissions within a particular namespace, when you create a Role, you have to specify the namespace it belongs in.

Under **_Resource Type_** - **_Authorization_** section you can view **_ClusterRoles_** and **_Roles_** resources on your cluster listed by namespace.

![Insights](/img/resource-view/autz-role.jpg)

Click on the **_cluster-autoscaler-aws-cluster-autoscaler_** role to view more details for that **_role_**. The below screenshot shows the **_cluster-autoscaler-aws-cluster-autoscaler_** role created under namespace **_kube-system_** which has authorization to **_delete_**, **_get_**, and **_update_** on **_configmaps_** resources.

![Insights](/img/resource-view/autz-role-detail.jpg)

A **[ClusterRoles](https://kubernetes.io/docs/reference/access-authn-authz/rbac/#role-and-clusterrole)** are a set of rules that are scoped to a cluster and not a namespace, which makes them different from a **_Role_**. **_ClusterRoles_** are additive, and you cannot set "deny" rules. You would generally use **_ClusterRoles_** to define cluster-wide permissions.

A **[Role binding](https://kubernetes.io/docs/reference/access-authn-authz/rbac/#rolebinding-and-clusterrolebinding)** grants role permissions to a user or set of users. Rolebindings are assigned to a particular namespace during creation. The Rolebinding resource holds a list of subjects (users, groups, or service accounts), and a reference to the role being granted. A **_RoleBinding_** grants permissions within a specific namespace like pods, replicasets, jobs, and deployments. Whereas a **_ClusterRoleBinding_** grants cluster scoped resources like nodes.

A **[ClusterRoleBinding](https://kubernetes.io/docs/reference/access-authn-authz/rbac/#rolebinding-and-clusterrolebinding)** attach **_ClusterRoles_** to a set of users. They are scoped to a cluster, and are not bound to namespaces like **_Roles_** and **_RoleBindings_**.

![Insights](/img/resource-view/authz-crolebinding.jpg)
