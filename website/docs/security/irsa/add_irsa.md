---
title: "Applying IRSA"
sidebar_position: 40
hide_table_of_contents: true
---

 
To use IAM roles for service accounts in your cluster, an `IAM OIDC Identity Provider` must be created and associated with the cluster. An OIDC has already been provisioned and associated with the `eks-workshop-cluster`

If you go to the Identity Providers in IAM Console, you will see OIDC provider has created for your cluster

![IAM OIDC Provider](./assets/oidc.png)

A IAM role which provides the required permissions to access the DynamoDB table has been created for you. You can view the policy like so:

```bash test=false
$ aws iam get-policy-version \
  --version-id v1 --policy-arn \
  arn:aws:iam::${AWS_ACCOUNT_ID}:policy/${EKS_CLUSTER_NAME}-carts-dynamo

  {
    "PolicyVersion": {
        "Document": {
            "Statement": [
                {
                    "Action": "dynamodb:*",
                    "Effect": "Allow",
                    "Resource": [
                        "arn:aws:dynamodb:us-east-2:XXXXXXXXXXXX:table/eks-workshop-cluster-carts",
                        "arn:aws:dynamodb:us-east-2:XXXXXXXXXXXX:table/eks-workshop-cluster-carts/index/*"
                    ],
                    "Sid": "AllAPIActionsOnCart"
                }
            ],
            "Version": "2012-10-17"
        },
        "VersionId": "v1",
        "IsDefaultVersion": true,
        "CreateDate": "2022-10-28T16:30:39+00:00"
    }
}
```





The role has also been configured with the appropriate trust relationship for our EKS cluster, which can been viewed like so:

```bash test=false
$ aws iam get-role --role-name ${EKS_CLUSTER_NAME}-carts-dynamo

{
    "Role": {
        "Path": "/",
        "RoleName": "eks-workshop-cluster-carts-dynamo",
        "RoleId": "AROASQ7BOHYVV7FQRO56O",
        "Arn": "arn:aws:iam::XXXXXXXXXXXX:role/eks-workshop-cluster-carts-dynamo",
        "CreateDate": "2022-10-28T16:51:00+00:00",
        "AssumeRolePolicyDocument": {
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Sid": "",
                    "Effect": "Allow",
                    "Principal": {
                        "Federated": "arn:aws:iam::XXXXXXXXXXXX:oidc-provider/oidc.eks.us-east-2.amazonaws.com/id/7185F12D2B62B8DA97B0ECA713F66C86"
                    },
                    "Action": "sts:AssumeRoleWithWebIdentity",
                    "Condition": {
                        "StringEquals": {
                            "oidc.eks.us-east-2.amazonaws.com/id/7185F12D2B62B8DA97B0ECA713F66C86:sub": "system:serviceaccount:carts:carts"
                        }
                    }
                }
            ]
        },
        "MaxSessionDuration": 3600,
        "RoleLastUsed": {
            "LastUsedDate": "2022-10-29T14:51:48+00:00",
            "Region": "us-east-2"
        }
    }
}
```

All thats left to us is to re-configure the `ServiceAccount` object used by the `carts` service to give it with the required annotation so that IRSA provides the correct Pods with the IAM role above.

```kustomization
security/irsa/service-account/carts-serviceAccount.yaml
ServiceAccount/carts
```

Run Kustomize to apply this change:

```bash
$ kubectl apply -k /workspace/modules/security/irsa/service-account
```

With the `ServiceAccount` updated now we just need to recycle the `carts` Pod so it picks up the new `ServiceAccount`:

```bash hook=enable-irsa
$ kubectl delete pod -n carts \
  -l app.kubernetes.io/component=service
```

