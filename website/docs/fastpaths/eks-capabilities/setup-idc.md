---
title: "Identity Center prerequisite"
sidebar_position: 5
sidebar_custom_props: { "info": true }
---

::required-time{estimatedLabExecutionTimeMinutes="1"}

The Argo CD EKS-managed capability authenticates **only** through AWS IAM Identity Center. There is no local admin user and no auto-generated password — anyone who signs in does so with an Identity Center identity that has been mapped to the Argo CD `ADMIN`, `EDITOR`, or `VIEWER` role.

Before `prepare-environment` can provision the capability, you need:

1. An IAM Identity Center instance enabled in this region.
2. An Identity Center **user** with a deliverable email and an enrolled MFA device — required because Identity Center forces email activation + MFA enrollment on first sign-in.
3. An Identity Center **group** containing that user, whose UUID you pass to Terraform via `ARGOCD_ADMIN_GROUP_ID`. The lab maps the group to the Argo CD `ADMIN` role.

Identity Center configuration is intentionally **not** managed by Terraform here. IDC users require real email activation, so a placeholder user created in code can never complete first sign-in.

:::info
This page is run **once per AWS account**. Once `argocd-admins` exists with you in it, you only need to re-export `ARGOCD_ADMIN_GROUP_ID` for new shells.
:::

## 1. Confirm Identity Center is enabled in this region

```bash test=false
$ aws sso-admin list-instances --query 'Instances[].InstanceArn' --output text | head -1
arn:aws:sso:::instance/ssoins-...
```

If that returns nothing, enable Identity Center once at the [IAM Identity Center console](https://console.aws.amazon.com/singlesignon/home) and re-run.

Capture the identity store ID for the steps below:

```bash test=false
$ export IDS=$(aws sso-admin list-instances \
    --query 'Instances[0].IdentityStoreId' --output text | head -1)
$ echo "IDS=$IDS"
IDS=d-xxxxxxxxxx
```

## 2. Create the admin user (Console)

The user must be created via the AWS Console because the Console flow is what triggers the activation email; `aws identitystore create-user` creates the record but does **not** send the activation email, leaving the user unable to sign in.

1. Open the [Identity Center Users page](https://console.aws.amazon.com/singlesignon/identity/home#!/instances/users).
2. Click **Add user**.
3. **Username** — anything you'll remember (e.g. your alias).
4. **Email address** — a real inbox you can receive mail at (your work email is fine). This is the address Identity Center sends the activation link to.
5. Fill in **First name** / **Last name**.
6. Click **Next**, then **Next** through the optional groups page (we'll add to a group in step 4), then **Add user**.
7. Within ~1 minute you'll receive an activation email. Click the link.
8. Set a permanent password and enroll an MFA device (TOTP authenticator app, hardware key, or SMS). Identity Center requires MFA for sign-in.

## 3. Create the admin group

Either via Console (**Groups** → **Create group** → name it `argocd-admins`) or via CLI:

```bash test=false
$ aws identitystore create-group \
    --identity-store-id "$IDS" \
    --display-name argocd-admins \
    --description "Argo CD administrators for the EKS Workshop fast path"
```

## 4. Add your user to the group

Replace `<paste-your-username>` below with the username you chose in step 2:

```bash test=false
$ MY_USERNAME="<paste-your-username>"

$ MY_USER_ID=$(aws identitystore list-users --identity-store-id "$IDS" \
    --query "Users[?UserName=='$MY_USERNAME'].UserId" --output text | head -1)
$ GROUP_ID=$(aws identitystore list-groups --identity-store-id "$IDS" \
    --query "Groups[?DisplayName=='argocd-admins'].GroupId" --output text | head -1)
$ echo "User: $MY_USER_ID  Group: $GROUP_ID"
```

Both `MY_USER_ID` and `GROUP_ID` should print non-empty UUIDs. If `MY_USER_ID` is empty, double-check the `MY_USERNAME` value matches the user you created in step 2 (the **Username**, not the email).

```bash test=false
$ aws identitystore create-group-membership \
    --identity-store-id "$IDS" \
    --group-id "$GROUP_ID" \
    --member-id "UserId=$MY_USER_ID"
```

Confirm the membership:

```bash test=false
$ aws identitystore list-group-memberships \
    --identity-store-id "$IDS" \
    --group-id "$GROUP_ID" \
    --query "GroupMemberships[?MemberId.UserId=='$MY_USER_ID']"
```

You should see one entry referencing your user ID.

## 5. Export the group UUID

This is what Terraform reads. The block re-derives the UUID directly from Identity Center so it works even in a fresh shell:

```bash test=false
$ export IDS=$(aws sso-admin list-instances \
    --query 'Instances[0].IdentityStoreId' --output text | head -1)
$ export ARGOCD_ADMIN_GROUP_ID=$(aws identitystore list-groups \
    --identity-store-id "$IDS" \
    --query "Groups[?DisplayName=='argocd-admins'].GroupId" --output text | head -1)
$ echo "ARGOCD_ADMIN_GROUP_ID=$ARGOCD_ADMIN_GROUP_ID"
ARGOCD_ADMIN_GROUP_ID=########-####-####-####-############
```

:::tip
Save the export to your shell profile (`~/.bashrc.d/idc.bash` inside the workshop IDE, or `~/.zshrc` on your Mac) so you don't have to repeat it every shell.
:::

## 6. Activate the user (set password and enroll MFA)

Identity Center won't let the user sign in to the Argo CD UI until they've activated the account: verified email, set a permanent password, and enrolled an MFA device. Pick whichever activation flow fits your situation.

### Email activation (recommended for self-service)

If the email address you set in step 2 is a real inbox you can receive mail at, just use the activation email Identity Center sent when the user was created.

1. Open the activation email from `no-reply@signin.aws` in your inbox. Subject is usually **"Invitation to join AWS IAM Identity Center"**.
2. Click **Accept invitation**. The link opens an AWS sign-in page bound to your user.
3. Set a permanent password.
4. Enroll an MFA device (TOTP authenticator app like Authy/Google Authenticator, hardware key, or SMS).
5. Sign-in is now ready.

If the email never arrived, in the [Users console](https://console.aws.amazon.com/singlesignon/identity/home#!/instances/users) click into the user and choose **Send email verification link** — Identity Center re-sends the activation message.


### Verify activation succeeded

The Identity Store API doesn't expose a per-user "activated" status, so confirm activation by signing in. First, find your account's IDC start portal URL — it's labeled **AWS access portal URL** in the Identity Center console under **Settings**. The URL looks like `https://<alias-or-ds-id>.awsapps.com/start`.

```bash test=false
$ aws sso-admin list-instances \
    --query 'Instances[0].IdentityStoreId' --output text
d-xxxxxxxxxx
```

Open the start portal URL in your browser, sign in with the username you set in step 2 and the password you just set, complete the MFA challenge. You should land on a "Your applications" page (it'll be empty until the Argo CD capability registers itself in step 7).

If sign-in succeeds, activation is complete. If it fails (e.g. "It's not you, it's us"), revisit Option B above and regenerate the one-time password.

## 7. Run `prepare-environment`

```bash test=false
$ prepare-environment fastpaths/eks-capabilities
```

If you forget to export `ARGOCD_ADMIN_GROUP_ID`, the preflight in `argocd-capability.tf` fails with a clear message before any AWS resources are created.

Once `prepare-environment` finishes, the next page verifies the capability is `ACTIVE`.

## Troubleshooting

**The CLI returns `ARGOCD_ADMIN_GROUP_ID=` (empty).** The `argocd-admins` group doesn't exist in this Identity Center instance. Re-run step 3 — confirm `aws identitystore create-group` returned a JSON object with `GroupId` before continuing.

**"It's not you, it's us" page after sign-in.** Identity Center couldn't activate the user — usually because the email was bogus or activation was never completed. Confirm the user is `ENABLED` (Identity Center console → Users → click user → status), and that you completed the password set + MFA enrollment from the activation email. The CLI shortcut `create-user` does **not** trigger activation; only the Console "Add user" flow does.

**`Caller does not have permission to perform sso:CreateApplication`.** The IDE role needs the SSO and Identity Store permissions added by the eks-capabilities IAM policy. If you're running outside the standard workshop IDE, deploy `lab/iam/policies/eks-capabilities.yaml` to your runner role.
