---
title: "Scenario - Multiline"
weight: 20
---

Scenario:

```bash
$ echo \
 "With default configuration this should run"

But this will not
```

```bash raw=true
echo \
 "With multiLine configuration this should run"

echo "And so will this"
```
