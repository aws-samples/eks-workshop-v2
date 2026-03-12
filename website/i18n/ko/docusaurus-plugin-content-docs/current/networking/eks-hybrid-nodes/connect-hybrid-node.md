---
title: "Hybrid Node 연결"
sidebar_position: 10
sidebar_custom_props: { "module": false }
weight: 20 # used by test framework
tmdTranslationSourceHash: 'a169f0cedba0153cc344d6f6e644aefa'
---

Amazon EKS Hybrid Nodes는 AWS SSM 하이브리드 활성화 또는 AWS IAM Roles Anywhere에서 프로비저닝한 임시 IAM 자격 증명을 사용하여 Amazon EKS 클러스터에 인증합니다. 이 워크샵에서는 SSM 하이브리드 활성화를 사용하겠습니다.

하이브리드 활성화를 생성하고 `ACTIVATION_ID` 및 `ACTIVATION_CODE` 환경 변수를 채우려면 다음 명령을 실행하세요:

```bash timeout=300 wait=30
$ export ACTIVATION_JSON=$(aws ssm create-activation \
--default-instance-name hybrid-ssm-node \
--iam-role $HYBRID_ROLE_NAME \
--registration-limit 1 \
--region $AWS_REGION)
$ export ACTIVATION_ID=$(echo $ACTIVATION_JSON | jq -r ".ActivationId")
$ export ACTIVATION_CODE=$(echo $ACTIVATION_JSON | jq -r ".ActivationCode")
```

활성화가 생성되었으므로 이제 인스턴스를 클러스터에 조인할 때 참조할 `NodeConfig`를 생성할 수 있습니다.

::yaml{file="manifests/modules/networking/eks-hybrid-nodes/nodeconfig.yaml" paths="spec.cluster,spec.hybrid.ssm"}

1. `$EKS_CLUSTER_NAME` 및 `$AWS_REGION` 환경 변수를 사용하여 대상 EKS 클러스터 `name`과 `region`을 지정합니다
2. 이전 단계에서 생성한 `$ACTIVATION_CODE` 및 `$ACTIVATION_ID` 환경 변수를 사용하여 SSM `activationCode`와 `activationId`를 지정합니다

```bash
$ cat ~/environment/eks-workshop/modules/networking/eks-hybrid-nodes/nodeconfig.yaml \
| envsubst > nodeconfig.yaml
```

이제 `nodeconfig.yaml`을 하이브리드 노드 인스턴스로 복사하겠습니다.

```bash timeout=300 wait=30
$ mkdir -p ~/.ssh/
$ ssh-keyscan -H $HYBRID_NODE_IP &> ~/.ssh/known_hosts
$ scp -i private-key.pem nodeconfig.yaml ubuntu@$HYBRID_NODE_IP:/home/ubuntu/nodeconfig.yaml
```

다음으로 EC2 인스턴스에서 `nodeadm`을 사용하여 하이브리드 노드 종속성을 설치하겠습니다. 여기에는 containerd, kubelet, kubectl, 그리고 AWS SSM 또는 AWS IAM Roles Anywhere 구성 요소가 포함됩니다. `nodeadm install`로 설치되는 구성 요소 및 파일 위치에 대한 자세한 내용은 하이브리드 노드 [nodeadm 참조](https://docs.aws.amazon.com/eks/latest/userguide/hybrid-nodes-nodeadm.html)를 참조하세요.

```bash timeout=300 wait=30
$ ssh -i private-key.pem ubuntu@$HYBRID_NODE_IP \
"sudo nodeadm install $EKS_CLUSTER_VERSION --credential-provider ssm"
```

종속성이 설치되고 `nodeconfig.yaml`이 준비되었으므로 인스턴스를 하이브리드 노드로 초기화합니다.

```bash timeout=300 wait=30
$ ssh -i private-key.pem ubuntu@$HYBRID_NODE_IP \
"sudo nodeadm init -c file://nodeconfig.yaml"
```

하이브리드 노드가 클러스터에 성공적으로 조인되었는지 확인해 보겠습니다. 자격 증명 공급자로 Systems Manager를 사용했기 때문에 하이브리드 노드는 `mi-` 접두사를 갖게 됩니다.

```bash timeout=300 wait=30
$ kubectl get nodes
NAME                                          STATUS     ROLES    AGE    VERSION
ip-10-42-118-191.us-west-2.compute.internal   Ready      <none>   1h   v1.31.3-eks-59bf375
ip-10-42-154-9.us-west-2.compute.internal     Ready      <none>   1h   v1.31.3-eks-59bf375
ip-10-42-163-120.us-west-2.compute.internal   Ready      <none>   1h   v1.31.3-eks-59bf375
mi-015a9aae5526e2192                          NotReady   <none>   5m     v1.31.4-eks-aeac579
```

좋습니다! 노드가 나타나지만 `NotReady` 상태입니다. 이는 하이브리드 노드가 워크로드를 처리할 준비가 되려면 CNI를 설치해야 하기 때문입니다. 먼저 Cilium Helm 리포지토리를 추가하겠습니다.

```bash timeout=300 wait=30
$ helm repo add cilium https://helm.cilium.io/
```

다음으로 Cilium helm 차트에 입력으로 제공할 구성 값을 살펴보겠습니다:

::yaml{file="manifests/modules/networking/eks-hybrid-nodes/cilium-values.yaml" paths="affinity.nodeAffinity,ipam.mode,ipam.operator.clusterPoolIPv4MaskSize,ipam.operator.clusterPoolIPv4PodCIDRList,operator.replicas,operator.affinity,operator.unmanagedPodWatcher.restart,envoy.enabled"}

1. 이 `affinity.nodeAffinity` 구성은 `eks.amazonaws.com/compute-type`으로 노드를 대상으로 지정하며, 각 노드에서 네트워킹을 처리하는 메인 CNI daemonset Pod가 `hybrid` 노드에서만 실행되도록 합니다
2. `ipam.mode`를 `cluster-pool`로 설정하여 Pod IP 할당에 클러스터 전체 IP 풀을 사용합니다
3. `clusterPoolIPv4MaskSize: 25`를 설정하여 노드당 할당되는 `/25` 서브넷을 지정합니다 (128개의 IP 주소)
4. `clusterPoolIPv4PodCIDRList`를 `10.53.0.0/16`으로 설정하여 하이브리드 노드 Pod를 위한 전용 CIDR을 지정합니다
5. `replicas: 1`로 설정하여 단일 operator 인스턴스가 실행되도록 지정합니다
6. 이 `affinity.nodeAffinity` 구성은 `eks.amazonaws.com/compute-type`으로 노드를 대상으로 지정하며, 각 노드에서 CNI 구성을 관리하는 메인 CNI operator Pod가 `hybrid` 노드에서만 실행되도록 합니다
7. `unmanagedPodWatcher.restart: false`로 설정하여 Pod 재시작 감시를 비활성화합니다
8. `envoy.enabled: false`로 설정하여 Envoy 프록시 통합을 비활성화합니다

이 구성을 사용하여 Cilium을 설치하겠습니다.

```bash timeout=300 wait=30
$ helm install cilium cilium/cilium \
--version 1.17.1 \
--namespace cilium \
--create-namespace \
--values ~/environment/eks-workshop/modules/networking/eks-hybrid-nodes/cilium-values.yaml
```

Cilium을 설치한 후 Hybrid Node가 정상적으로 실행되어야 합니다.

```bash timeout=300 wait=30
$ kubectl wait --for=condition=Ready nodes --all --timeout=2m
NAME                                          STATUS     ROLES    AGE    VERSION
ip-10-42-118-191.us-west-2.compute.internal   Ready      <none>   1h   v1.31.3-eks-59bf375
ip-10-42-154-9.us-west-2.compute.internal     Ready      <none>   1h   v1.31.3-eks-59bf375
ip-10-42-163-120.us-west-2.compute.internal   Ready      <none>   1h   v1.31.3-eks-59bf375
mi-015a9aae5526e2192                          Ready      <none>   5m   v1.31.4-eks-aeac579
```

완료되었습니다! 이제 클러스터에서 하이브리드 노드가 실행되고 있습니다.

