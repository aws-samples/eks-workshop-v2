---
title: "Crossplane Managed Resources"
sidebar_position: 20
---


## Provision AWS Resources

Lets look at provisioning AWS resources using Crossplane Managed Resources.
Managed Resouces are Kubernetes resources that are cluster scoped.
A Kuberentes user or tool will need cluster scope permission to create this type of resources.

Specify a Security Group manifest, this controls access to our database.
```file
crossplane/managed/rds-security-group.yaml
```
Specify a RDS DBSubnetGroup manifest, this configures the subnets that the database will be attach
```file
crossplane/managed/rds-dbgroup.yaml
```
Specify a RDS DBInstance manifest, this configures the database configuration like storage and engine.
```file
crossplane/managed/rds-instance.yaml
```

Create SecurityGroup, DBSubnetGroup, and DBInstance using the manifest files.
```bash
$ kubectl create ns catalog-prod || true
$ kubectl apply -k /workspace/modules/crossplane/managed
dbsubnetgroup.database.aws.crossplane.io/rds-eks-workshop created
securitygroup.ec2.aws.crossplane.io/rds-eks-workshop created
dbinstance.rds.aws.crossplane.io/rds-eks-workshop created
```

It takes some time to provision the AWS managed services, for RDS approximately 10 minutes. The AWS provider controller will report the status of the reconciliation in the status field of the Kubernetes custom resources.  
You can open the AWS console and see the services being created.

To verify that the provision is done, you can check that the condition “Ready” is true using the Kubernetes CLI.

Run the following commands and they will exit once the condition is met.
```bash timeout=1080
$ kubectl wait dbinstances.rds.aws.crossplane.io rds-eks-workshop --for=condition=Ready --timeout=15m
dbinstances.rds.services.k8s.aws/rds-eks-workshop condition met
```

Verify that the secret **catalog-db** has the correct information
```bash
$ if [[ "$(aws rds describe-db-instances --query "DBInstances[?DBInstanceIdentifier == 'rds-eks-workshop'].Endpoint.Address" --output text)" ==  "$(kubectl get secret catalog-db -o go-template='{{.data.endpoint|base64decode}}' -n catalog-prod)" ]]; then echo "Secret catalog configured correctly"; else echo "Error Catalo misconfigured"; false; fi
Secret catalog configured correctly
```


## Deploy the Application

The application will use the same manifest files as in development with the exception of the secret which contains the binding information that connects to AWS Services.

```bash
$ kubectl apply -k /workspace/modules/crossplane/manifests/
...
service/catalog created
...
deployment.apps/catalog created
...
```

## Access the Application

Verify that all pods are running in production

```bash
$ kubectl get pods -A | grep '\-prod'
assets-prod                    assets-7bd57dbfcc-cdp9j                         1/1     Running   0              1m
carts-prod                     carts-789498bdbd-wmb2q                          1/1     Running   0              1m
catalog-prod                   catalog-5c4b747759-7fphz                        1/1     Running   0              1m
checkout-prod                  checkout-66b6dcbc45-k9qjr                       1/1     Running   0              1m
orders-prod                    orders-59b94995cf-97pwz                         1/1     Running   0              1m
ui-prod                        ui-795bd46545-49jrh                             1/1     Running   0              1m
```

Get the hostname of the network load balancer for the UI and open it in the browser

```bash
$ kubectl get svc -n ui-prod ui-nlb
NAME     TYPE           CLUSTER-IP      EXTERNAL-IP                                           PORT(S)        AGE
ui-nlb   LoadBalancer   x.x.x.x         k8s-uiprod-uinlb-<uuid>.elb.<region>.amazonaws.com    80:32028/TCP   111m
```


## Cleanup

Delete the Application
```bash
$ kubectl delete -k /workspace/modules/crossplane/manifests/
```
Delete the Crossplane resources
```bash
$ kubectl delete -k /workspace/modules/crossplane/managed
$ kubectl delete ns catalog-prod
```
