---
title: "Sign in to Argo CD via Identity Center"
sidebar_position: 15
---

The managed Argo CD capability authenticates **only** through AWS IAM Identity Center. There is no local `admin` account and no auto-generated password. Anyone who signs in does so with an Identity Center identity mapped to one of the three built-in Argo CD roles (`ADMIN`, `EDITOR`, `VIEWER`).

This page gets your password and walks the **first sign-in** to the Argo CD UI. You reuse that password for the rest of this lab.

:::info
Signing in to the UI is **optional**. It lets you explore the Argo CD dashboard, but the rest of this lab works without it.
:::

### 1. Identity Center user and group

The workshop user and group are created once per environment and shared by every lab whose capability federates with Identity Center. There is a single Identity Center instance per account and Region, so a per-lab user would mean a separate first sign-in for each one. They were exported into your shell by `prepare-environment`:

```bash test=false
$ echo $EKS_CAP_ARGOCD_USER
eks-workshop
$ echo $EKS_CAP_ARGOCD_ADMIN_GROUP
eks-workshop-argocd-admins
```

Pre-created user

- `$EKS_CAP_ARGOCD_USER`: administrative user mapped to the Argo CD `ADMIN` role.

Pre-created group

- `$EKS_CAP_ARGOCD_ADMIN_GROUP`: group with administrative privileges, associated with the Argo CD capability.

### 2. Get your password

The environment setup already disabled MFA on the Identity Center instance it created and completed this user's first sign-in. Read the password from AWS Secrets Manager:

```bash test=false
$ aws secretsmanager get-secret-value --secret-id $EKS_CLUSTER_NAME-argocd-idc \
  --query SecretString --output text
```

### 3. First sign-in to Argo CD

Open the Argo CD URL in a new browser tab. The capability publishes it, so ask the EKS API for it rather than expecting it in the environment:

```bash test=false
$ aws eks describe-capability \
  --cluster-name $EKS_CLUSTER_AUTO_NAME \
  --capability-name $EKS_CAP_ARGOCD_CAPABILITY \
  --query 'capability.configuration.argoCd.serverUrl' --output text
```

1. Click **Log in via SSO**. Here, the SSO is powered by IAM Identity Center.
2. **Username:** the value of `$EKS_CAP_ARGOCD_USER`. Click **Next**.
3. **Password:** the password from step 2. Click **Sign in**.
4. You're redirected to the Argo CD **Applications** view as `ADMIN`.

![Argo CD UI after Identity Center sign-in](/img/fastpaths/eks-capabilities/argocd/argocd-ui-signed-in.png)

:::tip
You can also reach the UI from the **Amazon EKS console**: select your cluster, choose the **Capabilities** tab, choose **Argo CD**, then **Open Argo CD UI**. Both paths route through the same Identity Center sign-in.
:::

You're now ready to walk through the rest of this lab.

<!-- ## Troubleshooting

**"Register MFA device" screen instead of "Set new password".** MFA was not fully disabled in step 2. Return to **Identity Center → Settings → Authentication**, confirm **Prompt users for MFA** shows `Never (disabled)` on a fresh reload, then sign in again.

**"Incorrect username or password".** The OTP is single-use and expires quickly. Regenerate it in step 2 and try again. The OTP can also contain shell-special characters (e.g. `^&#<>`) that confuse some terminals when pasting, so type it manually if a paste seems garbled.

**"It's not you, it's us".** Identity Center couldn't activate the user. Use Reset password → "Generate a one-time password" (not the email-link option) to bypass the email round-trip.

**`Caller does not have permission to perform sso:CreateApplication` during `prepare-environment`.** The IDE role needs the SSO and Identity Store permissions provided by `lab/iam/policies/eks-capabilities.yaml`. If you're running outside the standard workshop IDE, attach that policy to your runner role. -->
