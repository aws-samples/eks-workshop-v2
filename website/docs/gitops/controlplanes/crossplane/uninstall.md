---
title: "Cleanup"
sidebar_position: 40
---

Uninstall the AWS `ProviderConfig` `default`

```bash
$ kubectl delete providerconfigs.aws.crossplane.io default
```

Uninstall the AWS `Provider` `aws-provider`
```bash
$ kubectl delete providers.pkg.crossplane.io aws-provider
```

Uninstall helm release `crossplane`
```bash
$ helm uninstall -n crossplane-system crossplane 
```