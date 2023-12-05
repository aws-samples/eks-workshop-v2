#!/bin/bash

kubectl delete networkpolicy default-deny -n ui --ignore-not-found > /dev/null
kubectl delete networkpolicy allow-ui-egress -n ui --ignore-not-found > /dev/null
kubectl delete networkpolicy allow-checkout-ingress-webservice  -n checkout --ignore-not-found > /dev/null
kubectl delete networkpolicy allow-checkout-ingress-redis -n checkout --ignore-not-found > /dev/null
kubectl delete networkpolicy default-deny-ingress -n checkout --ignore-not-found > /dev/null
kubectl delete networkpolicy allow-carts-ingress-webservice -n carts --ignore-not-found > /dev/null
kubectl delete ingress alb-ui -n ui --ignore-not-found > /dev/null
ADDON_ROLE_ARN=$(aws eks describe-addon --cluster-name "eks-workshop" --addon-name "vpc-cni" | jq -r '.addon.serviceAccountRoleArn')
ADDON_ROLE_NM=$(aws iam list-roles | jq -r ".Roles[] | select(.Arn == \"$ADDON_ROLE_ARN\") | .RoleName")
POLICY_ARN=$(aws iam list-policies | jq -r '.Policies[] | select(.PolicyName == "addon.cwlogs.allow") | .Arn')
aws iam detach-role-policy --role-name $ADDON_ROLE_NM --policy-arn $POLICY_ARN || true
aws iam delete-policy --policy-arn $POLICY_ARN || true