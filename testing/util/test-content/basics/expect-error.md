---
title: "Scenario - Expect Error"
weight: 30
---

Scenario:

```bash expectError=true
$ eklasmd0ajs0dasipod
# Under normal circumstances this would fail
```

```bash expectError=true hook=expect-error
$ ls -la
$ eklasmd0ajs0dasipod
# Under normal circumstances this would fail
```
