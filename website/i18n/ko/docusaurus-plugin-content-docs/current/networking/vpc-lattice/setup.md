---
title: "컨트롤러 배포"
sidebar_position: 10
tmdTranslationSourceHash: 91a3b9cd6266ae94a91ade2df0c27182
---

다음 지침에 따라 클러스터를 생성하고 AWS Gateway API Controller를 배포합니다.

먼저, VPC Lattice 네트워크에서 트래픽을 수신하도록 보안 그룹을 구성합니다. VPC Lattice와 통신하는 모든 Pod가 VPC Lattice 관리형 접두사 목록의 트래픽을 허용하도록 보안 그룹을 설정해야 합니다. 자세한 내용은 [보안 그룹을 사용하여 리소스에 대한 트래픽 제어](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_SecurityGroups.html)를 참조하세요. Lattice는 IPv4와 IPv6 접두사 목록을 모두 제공합니다.

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

이 단계에서는 Kubernetes Gateway API CRD와 해당 API의 구현을 제공하는 VPC Lattice 컨트롤러를 설치합니다:

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

이제 컨트롤러가 Deployment로 실행됩니다:

```bash
$ kubectl get deployment -n gateway-api-controller
NAME                                                  READY   UP-TO-DATE   AVAILABLE   AGE
gateway-api-controller-aws-gateway-controller-chart   2/2     2            2           24s
```

