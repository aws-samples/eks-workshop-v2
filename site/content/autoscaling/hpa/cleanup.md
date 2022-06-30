---
title: "Cleanup Scaling"
date: 2018-08-07T08:30:11-07:00
weight: 50
---

```bash
kubectl delete hpa,svc php-apache

kubectl delete deployment php-apache

kubectl delete pod load-generator

```
