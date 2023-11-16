#!/bin/bash

kubectl delete networkpolicy default-deny -n checkout --ignore-not-found > /dev/null
kubectl delete networkpolicy allow-ui-egress -n ui --ignore-not-found > /dev/null
kubectl delete networkpolicy allow-checkout-ingress-webservice  -n checkout --ignore-not-found > /dev/null
kubectl delete networkpolicy allow-checkout-ingress-redis -n checkout --ignore-not-found > /dev/null
kubectl delete networkpolicy default-deny-ingress -n checkout --ignore-not-found > /dev/null
kubectl delete networkpolicy allow-carts-ingress-webservice -n carts --ignore-not-found > /dev/null
