---
title: "コントローラーのデプロイ"
sidebar_position: 10
tmdTranslationSourceHash: 91a3b9cd6266ae94a91ade2df0c27182
---

クラスターを作成してAWS Gateway API Controllerをデプロイするには、以下の手順に従ってください。

まず、VPC Latticeネットワークからのトラフィックを受信するようにセキュリティグループを設定します。VPC Latticeと通信するすべてのPodがVPC Lattice管理のプレフィックスリストからのトラフィックを許可するように、セキュリティグループを設定する必要があります。詳細については、[セキュリティグループを使用したリソースへのトラフィックの制御](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_SecurityGroups.html)をご覧ください。LatticeにはIPv4とIPv6の両方のプレフィックスリストが利用可能です。

```bash
$ CLUSTER_SG=$(aws eks describe-cluster --name $EKS_CLUSTER_NAME --output json| jq -r '.cluster.resourcesVpcConfig.clusterSecurityGroupId')
$ PREFIX_LIST_ID=$(aws ec2 describe-managed-prefix-lists --query "PrefixLists[?PrefixListName=="\'com.amazonaws.$AWS_REGION.vpc-lattice\'"].PrefixListId" | jq -r '.[]')
$ aws ec2 authorize-security-group-ingress --group-id $CLUSTER_SG --ip-permissions "PrefixListIds=[{PrefixListId=${PREFIX_LIST_ID}}],IpProtocol=-1"
$ PREFIX_LIST_ID_IPV6=$(aws ec2 describe-managed-prefix-lists --query "PrefixLists[?PrefixListName=="\'com.amazonaws.$AWS_REGION.ipv6.vpc-lattice\'"].PrefixListId" | jq -r '.[]')
$ aws ec2 authorize-security-group-ingress --group-id $CLUSTER_SG --ip-permissions "PrefixListIds=[{PrefixListId=${PREFIX_LIST_ID_IPV6}}],IpProtocol=-1"

{
    "Return": true,
    "SecurityGroupRules": [
        {
            "SecurityGroupRuleId": "sgr-0cd3ce1b3cd1c8987",
            "GroupId": "sg-02182c4bf5e0c9756",
            "GroupOwnerId": "475846101383",
            "IsEgress": false,
            "IpProtocol": "-1",
            "FromPort": -1,
            "ToPort": -1,
            "PrefixListId": "pl-0cbf975b710a608ea"
        }
    ]
}
```

このステップでは、Kubernetes Gateway API CRDとそのAPIの実装を提供するVPC Latticeコントローラーをインストールします：

```bash wait=30
$ kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.2.0/standard-install.yaml
$ aws ecr-public get-login-password --region us-east-1 \
  | helm registry login --username AWS --password-stdin public.ecr.aws
$ helm install gateway-api-controller \
    oci://public.ecr.aws/aws-application-networking-k8s/aws-gateway-controller-chart \
    --version=v${LATTICE_CONTROLLER_VERSION} \
    --create-namespace \
    --set=aws.region=${AWS_REGION} \
    --set serviceAccount.annotations."eks\.amazonaws\.com/role-arn"="$LATTICE_IAM_ROLE" \
    --set=defaultServiceNetwork=${EKS_CLUSTER_NAME} \
    --namespace gateway-api-controller \
    --wait
```

これでコントローラーがデプロイメントとして実行されます：

```bash
$ kubectl get deployment -n gateway-api-controller
NAME                                                  READY   UP-TO-DATE   AVAILABLE   AGE
gateway-api-controller-aws-gateway-controller-chart   2/2     2            2           24s
```
