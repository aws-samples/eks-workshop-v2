---
title: "Sign in to Argo CD via Identity Center"
sidebar_position: 15
---

The managed Argo CD capability authenticates **only** through AWS IAM Identity Center. There is no local `admin` account and no auto-generated password — anyone who signs in does so with an Identity Center identity that has been mapped to one of the three built-in Argo CD roles (`ADMIN`, `EDITOR`, `VIEWER`).

This page walks the **one-time setup** of the workshop's IDC user plus the **first sign-in** to the Argo CD UI. After this, you reuse the password you set here for the rest of Lab 2.

Terraform handles the heavy lifting:

- Creates an Identity Center **group** (`${EKS_CLUSTER_AUTO_NAME}-argocd-admins`) and maps it to the Argo CD `ADMIN` role on the capability.
- Creates a single Identity Center **user** (`${EKS_CLUSTER_AUTO_NAME}-argocd-admin`) inside that group.

What's left for you is **two one-time admin actions** in the IAM Identity Center Console (disable MFA, generate a one-time password) plus a browser sign-in. There's no public AWS API to set an IDC password or skip MFA enrollment, so this is the simplest reliable activation path. Same approach as the [`saas-on-eks-workshop-capabilities`](https://github.com/aws-samples/saas-on-eks-workshop-capabilities) reference workshop.

:::caution
Disabling MFA weakens security for **all** users in the IAM Identity Center instance, not just the workshop user. Acceptable for a personal/dev/test account; **do not** apply this in a production account or shared organization.
:::

:::info
The rest of Lab 2 drives Argo CD entirely through the Kubernetes API so it stays fully testable. Signing in to the UI is **optional but recommended** — the visual graph of the catalog stack is the most engaging part of the lab.
:::

## 1. Confirm the env vars are populated

`prepare-environment` exported the values you'll need into your shell:

```bash test=false
$ echo $EKS_CAP_ARGOCD_USER
eks-workshop-...-argocd-admin
$ echo $EKS_CAP_ARGOCD_ADMIN_GROUP
eks-workshop-...-argocd-admins
$ echo $EKS_CAP_ARGOCD_URL
https://....eks-capabilities.us-west-2.amazonaws.com
```

## 2. Disable MFA on the Identity Center instance

This is a one-time, account-wide setting. Without it, first-time sign-in forces MFA enrollment, which can't be skipped from outside the activation portal.

1. Open the [IAM Identity Center console](https://console.aws.amazon.com/singlesignon/home).
2. In the left navigation, choose **Settings**.
3. Open the **Authentication** tab.
4. In the **Multi-factor authentication** section, click **Configure**.
5. Under **Prompt users for MFA**, choose **Never (disabled)**.
6. Scroll to the bottom and click **Save changes**. You should be returned to the Settings page; verify **Prompt users for MFA** now reads `Never (disabled)` on a fresh reload.

:::note
If you remain on the "Configure multi-factor authentication" screen after clicking **Save changes**, scroll down and click **Save changes** again — sometimes the button is below the fold and the first click misses.
:::

## 3. Generate a one-time password for the admin user

1. In the IAM Identity Center console, choose **Users** from the left navigation.
2. Find the user named `$EKS_CAP_ARGOCD_USER` (e.g. `eks-workshop-dev1-auto-argocd-admin`) and click into it.
3. Click **Reset password**.
4. Choose **Generate a one-time password and share the password with the user**, then click **Reset password**.
5. **Copy the temporary password from the dialog.** Keep the dialog open or paste the value somewhere safe — you'll need it in the next step.

:::note
The one-time password is single-use and expires quickly. If you don't sign in with it within a few minutes, regenerate from the same screen. AWS does not show the password again after you close the dialog.
:::

## 4. Sign in to Argo CD

Open the Argo CD URL in a new browser tab:

```bash test=false
$ echo $EKS_CAP_ARGOCD_URL
```

Then:

1. Click **Log in via AWS Identity Center**.
2. **Username:** the value of `$EKS_CAP_ARGOCD_USER`. Click **Next**.
3. **Password:** the one-time password you copied in step 3. Click **Sign in**.
4. Identity Center forces a **Set new password** screen on first sign-in (the OTP is single-use). Choose any new password and confirm it.
5. After setting the new password you'll be redirected to the Argo CD **Applications** view as ADMIN.

![Argo CD UI after Identity Center sign-in](/img/fastpaths/eks-capabilities/argocd/argocd-ui-signed-in.png)

:::tip
You can also reach the UI from the **Amazon EKS console**: select your cluster, choose the **Capabilities** tab, choose **Argo CD**, then **Open Argo CD UI**. Both paths route through the same Identity Center sign-in.
:::

You're now ready to walk through the rest of Lab 2.

## Troubleshooting

**"Register MFA device" screen instead of "Set new password".** MFA was not fully disabled in step 2. Return to **Identity Center → Settings → Authentication**, confirm **Prompt users for MFA** shows `Never (disabled)` on a fresh reload, then sign in again.

**"Incorrect username or password".** The OTP is single-use and expires quickly. Regenerate it via step 3 and try again. The OTP can also contain shell-special characters (e.g. `^&#<>`) that confuse some terminals when pasting — type it manually if a paste seems garbled.

**"It's not you, it's us".** Identity Center couldn't activate the user. Use Reset password → "Generate a one-time password" (not the email-link option) to bypass the email round-trip.

**`Caller does not have permission to perform sso:CreateApplication` during `prepare-environment`.** The IDE role needs the SSO and Identity Store permissions provided by `lab/iam/policies/eks-capabilities.yaml`. If you're running outside the standard workshop IDE, attach that policy to your runner role.

**You'd rather use the email-link activation flow.** Override the placeholder email by setting `TF_VAR_argocd_admin_email` to a real deliverable address before running `prepare-environment`:

```bash test=false
$ export TF_VAR_argocd_admin_email=you@example.com
$ prepare-environment fastpaths/eks-capabilities
```

AWS will send the user an activation email; click the link, set a password, enroll MFA. Skip steps 2–4 above (note: this still requires MFA enrollment unless you've disabled MFA in step 2).
