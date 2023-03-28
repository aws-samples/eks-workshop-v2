---
title: "Cleanup"
sidebar_position: 25
---

```bash
$ 
# Delete the VPC Lattice resources
$ kubectl delete -f ./workspace/modules/networking/vpc-lattice/routes
$ kubectl delete -f ./workspace/modules/networking/vpc-lattice/controller/eks-workshop-gw.yaml 
$ kubectl delete -f ./workspace/modules/networking/vpc-lattice/controller/gatewayclass.yaml 
$ kubectl delete -f ./workspace/modules/networking/vpc-lattice/controller/deployresources.yaml #use helm if you have used the helm installation steps!
$ eksctl delete iamserviceaccount --name=gateway-api-controller --cluster=${EKS_CLUSTER_NAME} --region ${AWS_DEFAULT_REGION} --namespace=system
# Restore the application to the previous state
$ kubectl patch svc checkout -n checkout --patch '{"spec": { "type": "ClusterIP", "ports": [ { "name": "http", "port": 80, "protocol": "TCP", "targetPort": "http" } ] } }'
$ CHECKOUT_IMG="public.ecr.aws/aws-containers/retail-store-sample-checkout:latest"
$ CHECKOUT_V2="public.ecr.aws/y1b0a4i8/checkoutv2:latest"
$ sed -i 's/checkoutv2/checkout/g' workspace/manifests/checkout/kustomization.yaml
$ sed -i "s|$CHECKOUT_V2|$CHECKOUT_IMG|g" workspace/manifests/checkout/deployment.yaml
$ CHECKOUT_SVC="http://checkout.checkout.svc:80"
$ kubectl patch configmap/ui -n ui --type merge -p '{"data":{"ENDPOINTS_CHECKOUT": "'${CHECKOUT_SVC}'"}}'
$ kubectl delete --all pods --namespace=ui
$ kubectl delete ns checkoutv2
```