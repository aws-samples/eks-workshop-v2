---
title: "Cleanup"
weight: 50
---

```bash timeout=60
kubectl delete hpa,svc php-apache

kubectl delete deployment php-apache
```
