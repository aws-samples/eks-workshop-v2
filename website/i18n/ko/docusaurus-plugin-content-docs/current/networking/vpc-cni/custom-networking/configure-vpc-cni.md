---
title: "Amazon VPC CNI 구성"
sidebar_position: 10
tmdTranslationSourceHash: 'e96a86fc4472ec29b1d77c88fbef5105'
---

먼저 Amazon VPC CNI를 구성하는 것으로 시작하겠습니다. 우리의 VPC는 `100.64.0.0/16` 범위를 가진 보조 CIDR을 추가하여 재구성되었습니다:

```bash
$ aws ec2 describe-vpcs --vpc-ids $VPC_ID | jq '.Vpcs[0].CidrBlockAssociationSet'
[
  {
    "AssociationId": "vpc-cidr-assoc-0ef3fae4a0abc4a42",
    "CidrBlock": "10.42.0.0/16",
    "CidrBlockState": {
      "State": "associated"
    }
  },
  {
    "AssociationId": "vpc-cidr-assoc-0a6577e1404081aef",
    "CidrBlock": "100.64.0.0/16",
    "CidrBlockState": {
      "State": "associated"
    }
  }
]
```

이는 이제 기본 CIDR 범위 외에 사용할 수 있는 별도의 CIDR 범위가 있음을 의미합니다. 위 출력에서 기본 CIDR 범위는 `10.42.0.0/16`입니다. 이 새로운 CIDR 범위에서 Pod 실행에 사용될 3개의 새로운 서브넷을 VPC에 추가했습니다:

```bash
$ echo "The secondary subnet in AZ $SUBNET_AZ_1 is $SECONDARY_SUBNET_1"
$ echo "The secondary subnet in AZ $SUBNET_AZ_2 is $SECONDARY_SUBNET_2"
$ echo "The secondary subnet in AZ $SUBNET_AZ_3 is $SECONDARY_SUBNET_3"
```

Custom networking을 활성화하려면 aws-node DaemonSet에서 `AWS_VPC_K8S_CNI_CUSTOM_NETWORK_CFG` 환경 변수를 _true_로 설정해야 합니다.

```bash wait=60
$ kubectl set env daemonset aws-node -n kube-system AWS_VPC_K8S_CNI_CUSTOM_NETWORK_CFG=true
```

그런 다음 Pod가 배포될 각 서브넷에 대해 `ENIConfig` 커스텀 리소스를 생성합니다:

```file
manifests/modules/networking/custom-networking/provision/eniconfigs.yaml
```

이를 클러스터에 적용해 보겠습니다:

```bash wait=30
$ kubectl kustomize ~/environment/eks-workshop/modules/networking/custom-networking/provision \
  | envsubst | kubectl apply -f-
```

`ENIConfig` 오브젝트가 생성되었는지 확인합니다:

```bash
$ kubectl get ENIConfigs
```

마지막으로 aws-node DaemonSet을 업데이트하여 EKS 클러스터에서 생성된 새로운 Amazon EC2 노드에 가용 영역에 대한 `ENIConfig`를 자동으로 적용하도록 합니다.

```bash wait=60
$ kubectl set env daemonset aws-node -n kube-system ENI_CONFIG_LABEL_DEF=topology.kubernetes.io/zone
```

