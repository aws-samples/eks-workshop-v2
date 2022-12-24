---
title: "Cleanup"
sidebar_position: 40
---

Uninstall the AWS Provider

```bash
$ kubectl delete providerconfigs.aws.crossplane.io default
$ kubectl delete providers.pkg.crossplane.io aws-provider
$ kubectl delete controllerconfigs.pkg.crossplane.io aws-controller-config
$ aws iam detach-role-policy --role-name crossplane-provider-aws --policy-arn "arn:aws:iam::aws:policy/AdministratorAccess" || true
$ aws iam delete-role --role-name crossplane-provider-aws || true
```


Uninstall helm release `crossplane`
```bash
$ helm uninstall -n crossplane-system crossplane 
```
