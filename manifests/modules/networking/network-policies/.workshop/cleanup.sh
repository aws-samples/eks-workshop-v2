#!/bin/bash

kubectl delete networkpolicy allow-ui-egress -n ui --ignore-not-found > /dev/null
kubectl delete networkpolicy allow-orders-ingress-webservice  -n orders --ignore-not-found > /dev/null
kubectl delete networkpolicy allow-catalog-ingress-webservice -n catalog --ignore-not-found > /dev/null
kubectl delete networkpolicy allow-catalog-ingress-db -n catalog --ignore-not-found > /dev/null
