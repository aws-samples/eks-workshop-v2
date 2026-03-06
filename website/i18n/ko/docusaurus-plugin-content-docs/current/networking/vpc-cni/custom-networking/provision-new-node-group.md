---
title: "새로운 Node Group 프로비저닝"
sidebar_position: 20
tmdTranslationSourceHash: '973e02ea92db1a8a09f9aa26b1d1fe67'
---

EKS 관리형 노드 그룹을 생성합니다:

```bash wait=10
$ aws eks create-nodegroup --region $AWS_REGION \
  --cluster-name $EKS_CLUSTER_NAME \
  --nodegroup-name custom-networking \
  --instance-types t3.medium --node-role $CUSTOM_NETWORKING_NODE_ROLE \
  --subnets $PRIMARY_SUBNET_1 $PRIMARY_SUBNET_2 $PRIMARY_SUBNET_3 \
  --labels type=customnetworking \
  --scaling-config minSize=1,maxSize=1,desiredSize=1
```

노드 그룹 생성은 몇 분이 소요됩니다. 다음 명령어를 사용하여 노드 그룹 생성이 완료될 때까지 기다릴 수 있습니다:

```bash timeout=300
$ aws eks wait nodegroup-active --cluster-name $EKS_CLUSTER_NAME --nodegroup-name custom-networking
```

완료되면 EKS 클러스터에 새로운 노드가 등록된 것을 확인할 수 있습니다:

```bash
$ kubectl get nodes -L eks.amazonaws.com/nodegroup
NAME                                            STATUS   ROLES    AGE   VERSION               NODEGROUP
ip-10-42-104-242.us-west-2.compute.internal     Ready    <none>   84m   vVAR::KUBERNETES_NODE_VERSION     default
ip-10-42-110-28.us-west-2.compute.internal      Ready    <none>   61s   vVAR::KUBERNETES_NODE_VERSION     custom-networking
ip-10-42-139-60.us-west-2.compute.internal      Ready    <none>   65m   vVAR::KUBERNETES_NODE_VERSION     default
ip-10-42-180-105.us-west-2.compute.internal     Ready    <none>   65m   vVAR::KUBERNETES_NODE_VERSION     default
```

새로운 노드 그룹의 이름으로 레이블이 지정된 새 노드 1개가 프로비저닝된 것을 확인할 수 있습니다.

