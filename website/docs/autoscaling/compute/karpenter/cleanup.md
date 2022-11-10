---
title: "Clean Up"
sidebar_position: 90
---

This module requires some manual cleanup due to the nature of the changes we made to our cluster. To make sure we can progress through the upcoming modules without issues we need to do some clean up steps.

Make sure to disable Karpenter by removing the provision:

```bash timeout=180 hook=karpenter-remove
$ kubectl delete provisioner default
```