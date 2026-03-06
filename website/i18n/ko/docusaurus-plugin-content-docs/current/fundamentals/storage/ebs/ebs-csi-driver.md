---
title: EBS CSI Driver
sidebar_position: 20
tmdTranslationSourceHash: '3c32323a8b3db48e3736c40ecaef5fd5'
---

이 섹션을 시작하기 전에 [Storage](../index.md) 메인 섹션에서 소개된 Kubernetes 스토리지 객체(볼륨, Persistent Volume (PV), Persistent Volume Claim (PVC), 동적 프로비저닝 및 임시 스토리지)에 대해 숙지하시기 바랍니다.

[**emptyDir**](https://kubernetes.io/docs/concepts/storage/volumes/#emptydir)은 임시 볼륨의 예시이며, 현재 MySQL StatefulSet에서 이를 사용하고 있습니다. 하지만 이번 챕터에서는 Dynamic Volume Provisioning을 사용하여 Persistent Volume (PV)으로 업데이트할 것입니다.

[Kubernetes Container Storage Interface (CSI)](https://kubernetes-csi.github.io/docs/)는 상태 저장 컨테이너화된 애플리케이션을 실행하는 데 도움을 줍니다. CSI 드라이버는 Kubernetes 클러스터가 Persistent Volume의 라이프사이클을 관리할 수 있도록 하는 CSI 인터페이스를 제공합니다. Amazon EKS는 Amazon EBS용 CSI 드라이버를 제공하여 상태 저장 워크로드를 더 쉽게 실행할 수 있도록 합니다.

EKS 클러스터에서 동적 프로비저닝과 함께 Amazon EBS 볼륨을 활용하려면 EBS CSI Driver가 설치되어 있는지 확인해야 합니다. [Amazon Elastic Block Store (Amazon EBS) Container Storage Interface (CSI) 드라이버](https://github.com/kubernetes-sigs/aws-ebs-csi-driver)를 사용하면 Amazon Elastic Kubernetes Service (Amazon EKS) 클러스터가 Persistent Volume용 Amazon EBS 볼륨의 라이프사이클을 관리할 수 있습니다.

보안을 개선하고 작업량을 줄이기 위해 Amazon EBS CSI 드라이버를 Amazon EKS 애드온으로 관리할 수 있습니다. 애드온에 필요한 IAM role이 이미 생성되어 있으므로 바로 애드온을 설치할 수 있습니다:

```bash timeout=300 wait=60
$ aws eks create-addon --cluster-name $EKS_CLUSTER_NAME --addon-name aws-ebs-csi-driver \
  --service-account-role-arn $EBS_CSI_ADDON_ROLE \
  --configuration-values '{"defaultStorageClass":{"enabled":true}}'
$ aws eks wait addon-active --cluster-name $EKS_CLUSTER_NAME --addon-name aws-ebs-csi-driver
```

이제 애드온이 EKS 클러스터에 생성한 것들을 살펴볼 수 있습니다. 예를 들어, DaemonSet은 클러스터의 각 노드에서 Pod를 실행하고 있습니다:

```bash
$ kubectl get daemonset ebs-csi-node -n kube-system
NAME           DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR            AGE
ebs-csi-node   3         3         3       3            3           kubernetes.io/os=linux   3d21h
```

EKS 1.30부터 EBS CSI Driver는 [Amazon EBS GP3 볼륨 타입](https://docs.aws.amazon.com/ebs/latest/userguide/general-purpose.html#gp3-ebs-volume-type)으로 구성된 기본 [StorageClass](https://kubernetes.io/docs/concepts/storage/storage-classes/) 객체를 사용합니다. 다음 명령을 실행하여 확인하세요:

```bash
$ kubectl get storageclass
NAME                           PROVISIONER             RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
ebs-csi-default-sc (default)   ebs.csi.aws.com         Delete          WaitForFirstConsumer   true                   96s
gp2                            kubernetes.io/aws-ebs   Delete          WaitForFirstConsumer   false                  9d
```

이제 EKS Storage와 Kubernetes 객체에 대해 더 잘 이해했으니, 다음 페이지에서는 Kubernetes 동적 볼륨 프로비저닝을 사용하여 데이터베이스 파일의 영구 스토리지로 EBS 블록 스토어 볼륨을 활용하도록 catalog 마이크로서비스의 MySQL DB StatefulSet을 수정하는 데 집중하겠습니다.

