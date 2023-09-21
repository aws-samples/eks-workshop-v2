---
title: "Cleanup"
sidebar_position: 100
---

Delete all the network policies that we created as part of our labs.

```bash wait=30 timeout=240
$ kubectl delete networkpolicy allow-ui-egress -n ui
$ kubectl delete networkpolicy allow-orders-ingress-webservice  -n orders
$ kubectl delete networkpolicy allow-catalog-ingress-webservice -n catalog
$ kubectl delete networkpolicy allow-catalog-ingress-db -n catalog
```