---
title: "Sign in to Argo CD"
sidebar_position: 30
sidebar_custom_props: { "info": true }
---

The managed Argo CD capability uses **AWS Identity Center** as its only authentication source. There is no local `admin` account and no auto-generated password — anyone who signs in does so with an Identity Center identity that has been mapped to one of the three built-in Argo CD roles (`ADMIN`, `EDITOR`, `VIEWER`).

This fast path treats the Identity Center group as a **one-time prerequisite** the learner sets up in the IDC console (covered on the previous page). The group's UUID was passed into Terraform as `argocd_admin_group_id` and the capability now maps it to the Argo CD `ADMIN` role:

```bash test=false
$ echo $EKS_CAP_ARGOCD_ADMIN_GROUP_ID
########-####-####-####-############
```

:::info
This lab drives Argo CD entirely through the Kubernetes API so it stays fully testable. Signing in to the Argo CD UI is **optional** and requires an interactive browser flow through Identity Center, so the commands on this page are not run by the automated tests.
:::

## Exploring the UI

The Argo CD UI is reachable at the capability's server URL:

```bash test=false
$ echo $EKS_CAP_ARGOCD_URL
https://....eks-capabilities.us-west-2.amazonaws.com
```

Open that URL in your browser and choose **Log in via AWS Identity Center**. Sign in with the Identity Center user you assigned to the admin group during setup. After authentication you'll land in the Argo CD dashboard. It will be empty for now — we'll create an `Application` in the next step and you can refresh the UI to watch it sync.

![Argo CD UI after Identity Center sign-in](/img/fastpaths/eks-capabilities/argocd/argocd-ui-signed-in.png)

You can also reach the UI from the Amazon EKS console: select your cluster, choose the **Capabilities** tab, choose **Argo CD**, then **Open Argo CD UI**.

:::tip
Forgot to add yourself to the admin group during the setup step? You can do it now:

```bash test=false
$ IDS=$(aws sso-admin list-instances \
    --query 'Instances[0].IdentityStoreId' --output text | head -1)
$ MY_USER_ID=$(aws identitystore list-users --identity-store-id "$IDS" \
    --query "Users[?UserName=='YOUR_USERNAME'].UserId" --output text | head -1)
$ aws identitystore create-group-membership \
    --identity-store-id "$IDS" \
    --group-id "$EKS_CAP_ARGOCD_ADMIN_GROUP_ID" \
    --member-id "UserId=$MY_USER_ID"
```
:::

In the next page, we'll declare the `catalog` Application with `kubectl apply` and let Argo CD reconcile it from the seeded CodeCommit repository.
