---
title: "Basics"
weight: 10
---

Some basics

```bash
$ command1
```

```
$ This should be ignored
```

```bash timeout=10
$ command1
```

```bash expectError=true
$ command1
```

```bash test=false
$ command1
```

```bash hook=example
$ command1
```

```bash raw=true
command1
command2
```

```bash wait=30
$ command1
```

```bash
$ command1
some output
$ command2
```

```bash
$ command1 \
line2 \
line3
some output
```

```bash
$ cat <<EOF > /tmp/yourfilehere
check this
EOF
some output
```