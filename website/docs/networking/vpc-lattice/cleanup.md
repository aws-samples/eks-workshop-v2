---
title: "Cleanup"
sidebar_position: 25
---

Delete VPC Lattice resources:

```bash
$ kubectl delete -f ./eks-workshop/manifests/modules/networking/vpc-lattice/routes
$ kubectl delete -f ./eks-workshop/manifests/modules/networking/vpc-lattice/controller/eks-workshop-gw.yaml 
$ kubectl delete -f ./eks-workshop/manifests/modules/networking/vpc-lattice/controller/gatewayclass.yaml 
```

Restore the application to the previous state

```bash
$ kubectl patch svc checkout -n checkout --patch '{"spec": { "type": "ClusterIP", "ports": [ { "name": "http", "port": 80, "protocol": "TCP", "targetPort": "http" } ] } }'
$ CHECKOUT_SVC="http://checkout.checkout.svc:80"
$ kubectl patch configmap/ui -n ui --type merge -p '{"data":{"ENDPOINTS_CHECKOUT": "'${CHECKOUT_SVC}'"}}'
$ kubectl delete --all pods --namespace=ui
$ kubectl delete -k /eks-workshop/manifests/modules/networking/vpc-lattice/abtesting/
```

Delete the AWS Gateway API Controller. 

```bash
$ helm delete gateway-api-controller --namespace system
```

Delete the IAM Service account, policy and `system` namespace.

```bash
$ eksctl delete iamserviceaccount --name=gateway-api-controller --cluster=${EKS_CLUSTER_NAME} --region ${AWS_DEFAULT_REGION} --namespace=system
$ export VPCLatticeControllerIAMPolicyArn=$(aws iam list-policies --query 'Policies[?PolicyName==`VPCLatticeControllerIAMPolicy`].Arn' --output text)
$ aws iam delete-policy --policy-arn=${VPCLatticeControllerIAMPolicyArn}
$ kubectl delete -f /eks-workshop/manifests/modules/networking/vpc-lattice/controller/deploy-namesystem.yaml
```
