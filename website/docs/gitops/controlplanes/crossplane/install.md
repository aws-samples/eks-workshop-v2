---
title: "Install Crossplane"
sidebar_position: 10
---


## IAM Setup
Create the IAM role with the trust relationship with the Service Account for the AWS Crossplane Provider Controller.
This role will be use to provision the AWS Managed resources. 


View the IAM trust policy running `cat /workspace/modules/crossplane/trust.json`
>The values `${AWS_ACCOUNT_ID}` and `${OIDC_PROVIDER}` will be substituted from environment variables.

Create the `crossplane-provider-aws` IAM Role using the assume role policy document `trust.json` and attach the policy with `AdministratorAccess`

```bash hook=crossplane-install
$ aws iam create-role --role-name "crossplane-provider-aws" --assume-role-policy-document "$(envsubst </workspace/modules/crossplane/trust.json)"

$ aws iam attach-role-policy --role-name crossplane-provider-aws --policy-arn "arn:aws:iam::aws:policy/AdministratorAccess"
```

> NOTE: This example role uses `AdministratorAccess` for demo purpose only, but you should select a policy with the minimum permissions required to provision your resources.


## Install Crossplane

Use Helm 3 to install the latest official `stable` release of Crossplane:

```bash
$ helm repo add crossplane-stable https://charts.crossplane.io/stable
"crossplane-stable" has been added to your repositories
$ helm repo update
Update Complete
$ helm install crossplane crossplane-stable/crossplane \
  --version 1.10.1 \
  --namespace crossplane-system \
  --create-namespace \
  --wait
NAME: crossplane
NAMESPACE: crossplane-system
STATUS: deployed
REVISION: 1
kubectl wait --for condition=established --timeout=60s crd/providers.pkg.crossplane.io
...
```

## Install AWS Provider for Crossplane

Install the AWS `Provider` `aws-provider` and `ControllerConfig` `aws-controller-config`

View the manifest with `cat /workspace/modules/crossplane/aws-provider/aws-provider.yaml`
>The values `${AWS_ACCOUNT_ID}` will be substituted from environment variable.

The name of the provider `aws-provider` will determined the service account name prefix (ie `aws-provider-*`) for the provider controller.
We already configured IAM to allow this service account to assume the role we created above.

```bash
$ envsubst < /workspace/modules/crossplane/aws-provider/aws-provider.yaml | kubectl apply -f -
$ kubectl wait --for condition=established --timeout=60s crd/providerconfigs.aws.crossplane.io
```

Install the AWS `ProviderConfig` `default`

```bash
$ kubectl apply -f /workspace/modules/crossplane/aws-provider/aws-provider-config.yaml
```