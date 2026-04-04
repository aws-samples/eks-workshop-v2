---
title: "클러스터 오버 프로비저닝"
sidebar_position: 50
tmdTranslationSourceHash: 'd62623f459247d11cec4ad17320371d7'
---

AWS용 Kubernetes [Cluster Autoscaler (CA)](https://github.com/kubernetes/autoscaler/blob/master/cluster-autoscaler/cloudprovider/aws/README.md)는 [EKS node group](https://docs.aws.amazon.com/eks/latest/userguide/managed-node-groups.html)의 [AWS EC2 Auto Scaling group (ASG)](https://docs.aws.amazon.com/autoscaling/ec2/userguide/auto-scaling-groups.html)을 구성하여 스케줄링 대기 중인 Pod가 있을 때 클러스터의 노드를 확장합니다.

ASG를 수정하여 클러스터에 노드를 추가하는 이 프로세스는 Pod가 스케줄링되기 전에 추가 시간이 소요됩니다. 예를 들어, 이전 섹션에서 애플리케이션 스케일링 중에 생성된 Pod가 사용 가능해지기까지 몇 분이 걸린 것을 확인했을 수 있습니다.

이 문제를 해결하는 다양한 접근 방식이 있습니다. 이 실습 연습에서는 플레이스홀더로 사용되는 낮은 우선순위 Pod를 실행하는 추가 노드로 클러스터를 "오버 프로비저닝"하여 이 문제를 해결합니다. 이러한 낮은 우선순위 Pod는 중요한 애플리케이션 Pod가 배포될 때 제거됩니다. 플레이스홀더 Pod는 CPU 및 메모리 리소스를 예약할 뿐만 아니라 [AWS VPC Container Network Interface - CNI](https://docs.aws.amazon.com/eks/latest/userguide/pod-networking.html)에서 할당된 IP 주소도 확보합니다.

