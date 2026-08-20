---
title: "Argo CD"
sidebar_position: 3
sidebar_custom_props: { "module": true }
description: "Declarative, GitOps continuous delivery with Argo CD on Amazon Elastic Kubernetes Service."
---

::required-time

<details>
<summary>In your own account, read this for <strong>Prerequisites - IAM Identity Center</strong></summary>

The Amazon EKS Capability for Argo CD authenticates users through AWS IAM Identity Center, so this lab needs an Identity Center instance in the same account and Region as your cluster, holding a user to sign in as. At an AWS-run event this is already set up for you; in your own account you need an instance and an Argo CD admin user in place before you start.

The lab only reads from Identity Center — it will not enable the service and will not create the user, because both write to an account-wide directory that may hold identities you care about. Set them up once with the steps below.

**Run these commands with administrator credentials, outside the workshop IDE.** The IDE's IAM role deliberately excludes `sso:CreateInstance` and `identitystore:CreateUser`, so they fail with `AccessDeniedException` in the IDE terminal. Use a shell or console session that has administrator access to the account, then return to the IDE for the rest of the lab. You can also do all of this from the [IAM Identity Center console](https://console.aws.amazon.com/singlesignon) if you prefer.

**1. Enable IAM Identity Center** and wait for it to become `ACTIVE`, which usually takes under a minute:

```bash test=false
$ aws sso-admin create-instance --name eks-workshop
$ aws sso-admin list-instances --query 'Instances[0].Status'
"ACTIVE"
```

**Already have an Identity Center instance in this account and Region?** Skip this step and go straight to creating the user. The lab reuses the existing instance and will not change its settings, including its MFA policy.

**2. Create the Argo CD administrator** the lab expects:

```bash test=false
$ export IDENTITY_STORE_ID=$(aws sso-admin list-instances --no-paginate \
  --query 'Instances[0].IdentityStoreId' --output text)
$ aws identitystore create-user \
  --identity-store-id $IDENTITY_STORE_ID \
  --user-name eks-workshop \
  --display-name 'ArgoCD Workshop Admin' \
  --name 'GivenName=ArgoCD,FamilyName=Admin' \
  --emails 'Value=eks-workshop@example.com,Primary=true'
```

**3. Give the user a password.** Identity Center creates users without one and has no API to set one, so this happens through a first sign-in and is covered in [Accessing Argo CD](./access_argocd.md). At an AWS-run event the event provisioning does it for you.

**Organization instances are not supported.** If your account belongs to an AWS Organization that has IAM Identity Center enabled in its management account, this lab will refuse to run — it will not register an Argo CD application or a workshop user in a directory the account does not own. Use a standalone account with its own Identity Center instance instead.

</details>

:::tip Before you start
Prepare your environment for this section:

```bash timeout=900 wait=120
$ prepare-environment automation/gitops/argocd
```

This will make the following changes to your lab environment:

- Create an AWS CodeCommit repository
- Create an IAM role for the EKS Capability for Argo CD
- Grant the IAM Identity Center user set up above ADMIN access to Argo CD
- Deploy the Amazon EKS Capability for Argo CD

You can view the Terraform that applies these changes [here](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/automation/gitops/argocd/.workshop/terraform).

:::

[Argo CD](https://argoproj.github.io/cd/) is a declarative continuous delivery tool for Kubernetes that implements GitOps principles. With the Amazon EKS Capability for Argo CD, the Argo CD runs in the AWS control plane — not on your worker nodes — giving you the full GitOps workflow without the operational overhead of installing, scaling, or maintaining Argo CD components yourself.

As a CNCF graduated project, Argo CD offers several key features:

- An intuitive web UI for deployment management
- Multi-cluster configuration support
- Integration with CI/CD pipelines
- Robust access controls
- Drift detection capabilities
- Support for various deployment strategies
- AWS-managed availability, scaling, and upgrades
- Native IAM Identity Center integration for SSO authentication

By using Argo CD, you can ensure that your Kubernetes applications remain consistent with their source configurations and automatically remediate any drift that occurs between the desired and actual states.
