---
title: "Clean Up"
sidebar_position: 50
---

You have successfully demonstrated the use of prefix mode networking! Let’s cleanup the unused pods to avoid issues in other modules.

```bash wait=10
$ kubectl delete -f \
  /workspace/modules/networking/prefix/deployment-pause.yaml
```