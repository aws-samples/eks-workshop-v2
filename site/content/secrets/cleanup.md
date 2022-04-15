---
title: "Cleanup The Lab"
weight: 12
---

#### Remove The Namespace

Let's delete the namespace for this exercise:

```bash timeout=60
rm -f test-creds
rm -f podconsumingsecret.yaml
kubectl delete ns secretslab
```

Output:

{{< output >}}
namespace "secretslab" deleted
{{< /output >}}

This cleans up the secret and pod we deployed for this lab.
