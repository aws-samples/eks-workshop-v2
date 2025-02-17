---
title: "클러스터 오버프로비저닝"
sidebar_position: 50
---

Kubernetes의 [AWS용 클러스터 오토스케일러(CA)](https://github.com/kubernetes/autoscaler/blob/master/cluster-autoscaler/cloudprovider/aws/README.md)는 파드가 스케줄링을 대기 중일 때 클러스터의 노드를 스케일링하기 위해 [EKS 노드 그룹](https://docs.aws.amazon.com/eks/latest/userguide/managed-node-groups.html)의 [AWS EC2 오토 스케일링 그룹(ASG)](https://docs.aws.amazon.com/autoscaling/ec2/userguide/auto-scaling-groups.html)을 구성합니다.

ASG를 수정하여 클러스터에 노드를 추가하는 이 프로세스는 본질적으로 파드가 스케줄링될 수 있기까지 추가 시간이 소요됩니다. 예를 들어, 이전 섹션에서 애플리케이션 스케일링 중에 생성된 파드가 사용 가능하게 되기까지 몇 분이 걸렸다는 것을 알 수 있었을 것입니다.

이 문제를 해결하기 위한 다양한 접근 방식이 있습니다. 이 실습에서는 자리표시자로 사용되는 낮은 우선순위 파드를 실행하는 추가 노드로 클러스터를 "오버프로비저닝"하여 이 문제를 해결합니다. 이러한 낮은 우선순위 파드는 중요한 애플리케이션 파드가 배포될 때 축출됩니다. 자리표시자 파드는 CPU와 메모리 리소스를 예약할 뿐만 아니라 [AWS VPC 컨테이너 네트워크 인터페이스 - CNI](https://docs.aws.amazon.com/eks/latest/userguide/pod-networking.html)에서 할당된 IP 주소도 확보합니다.