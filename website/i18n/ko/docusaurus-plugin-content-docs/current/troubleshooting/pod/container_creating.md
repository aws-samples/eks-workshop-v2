---
title: "PodStuck - ContainerCreating"
sidebar_position: 73
tmdTranslationSourceHash: 'ca6702af7a03ccc3060495f71996fd4e'
---

이 섹션에서는 ContainerCreating 상태에서 멈춰 있는 Pod의 문제를 해결하는 방법을 배웁니다. 이제 배포가 생성되었는지 확인하여 시나리오의 문제 해결을 시작할 수 있습니다.

```bash
$ kubectl get deploy efs-app -n default
NAME      READY   UP-TO-DATE   AVAILABLE   AGE
efs-app   0/1     1            0           18m
```

:::info
동일한 출력이 표시되면 문제 해결을 시작할 준비가 된 것입니다.
:::

이 문제 해결 섹션의 작업은 efs-app 배포가 0/1 준비 상태인 원인을 찾고 이를 수정하여 배포가 하나의 Pod를 준비 및 실행 상태로 만드는 것입니다.

## 문제 해결을 시작해 봅시다

### 1단계: Pod 상태 확인

먼저 Pod의 상태를 확인해야 합니다.

```bash
$ kubectl get pods -l app=efs-app
NAME                       READY   STATUS              RESTARTS   AGE
efs-app-5c4df89785-m4qz4   0/1     ContainerCreating   0          19m
```

### 2단계: Pod 설명 확인

Pod 상태가 ContainerCreating으로 표시되는 것을 볼 수 있습니다. Pod를 설명하여 이벤트를 확인해 봅시다.

```bash expectError=true
$ export POD=`kubectl get pods -l app=efs-app -o jsonpath='{.items[*].metadata.name}' | tr ' ' '\n' | grep efs`
$ kubectl describe pod $POD | awk '/Events:/,/^$/'
Events:
  Type     Reason            Age                From               Message
  ----     ------            ----               ----               -------
  Warning  FailedMount       26m (x3 over 26m)  kubelet            MountVolume.SetUp failed for volume "pvc-719c8ef2-5bdb-4638-b4db-7d59b53d21f0" : rpc error: code = Internal desc = Could not mount "fs-00a4069aec7924c8c:/" at "/var/lib/kubelet/pods/b2db07f9-0bae-4324-98e6-e4c978a0bef5/volumes/kubernetes.io~csi/pvc-719c8ef2-5bdb-4638-b4db-7d59b53d21f0/mount": mount failed: exit status 1
Mounting command: mount
Mounting arguments: -t efs -o accesspoint=fsap-0488d7b0bd9c26425,tls fs-00a4069aec7924c8c:/ /var/lib/kubelet/pods/b2db07f9-0bae-4324-98e6-e4c978a0bef5/volumes/kubernetes.io~csi/pvc-719c8ef2-5bdb-4638-b4db-7d59b53d21f0/mount
Output: Failed to resolve "fs-00a4069aec7924c8c.efs.us-west-2.amazonaws.com". The file system mount target ip address cannot be found, please pass mount target ip address via mount options.
No mount target created for the file system fs-00a4069aec7924c8c is in available state yet, please retry in 5 minutes.
Warning: config file does not have fips_mode_enabled item in section mount.. You should be able to find a new config file in the same folder as current config file /etc/amazon/efs/efs-utils.conf. Consider update the new config file to latest config file. Use the default value [fips_mode_enabled = False].Warning: config file does not have fips_mode_enabled item in section mount.. You should be able to find a new config file in the same folder as current config file /etc/amazon/efs/efs-utils.conf. Consider update the new config file to latest config file. Use the default value [fips_mode_enabled = False].
  Warning  FailedMount  26m (x3 over 26m)  kubelet  MountVolume.SetUp failed for volume "pvc-719c8ef2-5bdb-4638-b4db-7d59b53d21f0" : rpc error: code = Internal desc = Could not mount "fs-00a4069aec7924c8c:/" at "/var/lib/kubelet/pods/b2db07f9-0bae-4324-98e6-e4c978a0bef5/volumes/kubernetes.io~csi/pvc-719c8ef2-5bdb-4638-b4db-7d59b53d21f0/mount": mount failed: exit status 1
Mounting command: mount
Mounting arguments: -t efs -o accesspoint=fsap-0488d7b0bd9c26425,tls fs-00a4069aec7924c8c:/ /var/lib/kubelet/pods/b2db07f9-0bae-4324-98e6-e4c978a0bef5/volumes/kubernetes.io~csi/pvc-719c8ef2-5bdb-4638-b4db-7d59b53d21f0/mount
Output: Failed to resolve "fs-00a4069aec7924c8c.efs.us-west-2.amazonaws.com". Cannot connect to file system mount target ip address 10.42.41.35.
Connection to the mount target IP address 10.42.41.35 timeout. Please retry in 5 minutes if the mount target is newly created. Otherwise check your VPC and security group configuration to ensure your file system is reachable via TCP port 2049 from your instance.
Warning: config file does not have fips_mode_enabled item in section mount.. You should be able to find a new config file in the same folder as current config file /etc/amazon/efs/efs-utils.conf. Consider update the new config file to latest config file. Use the default value [fips_mode_enabled = False].Warning: config file does not have fips_mode_enabled item in section mount.. You should be able to find a new config file in the same folder as current config file /etc/amazon/efs/efs-utils.conf. Consider update the new config file to latest config file. Use the default value [fips_mode_enabled = False].
  Warning  FailedMount  19m  kubelet  MountVolume.SetUp failed for volume "pvc-719c8ef2-5bdb-4638-b4db-7d59b53d21f0" : rpc error: code = Internal desc = Could not mount "fs-00a4069aec7924c8c:/" at "/var/lib/kubelet/pods/b2db07f9-0bae-4324-98e6-e4c978a0bef5/volumes/kubernetes.io~csi/pvc-719c8ef2-5bdb-4638-b4db-7d59b53d21f0/mount": mount failed: exit status 32
Mounting command: mount
Mounting arguments: -t efs -o accesspoint=fsap-0488d7b0bd9c26425,tls fs-00a4069aec7924c8c:/ /var/lib/kubelet/pods/b2db07f9-0bae-4324-98e6-e4c978a0bef5/volumes/kubernetes.io~csi/pvc-719c8ef2-5bdb-4638-b4db-7d59b53d21f0/mount
Output: Could not start amazon-efs-mount-watchdog, unrecognized init system "aws-efs-csi-dri"
Mount attempt 1/3 failed due to timeout after 15 sec, wait 0 sec before next attempt.
Mount attempt 2/3 failed due to timeout after 15 sec, wait 0 sec before next attempt.
b'mount.nfs4: mount point /var/lib/kubelet/pods/b2db07f9-0bae-4324-98e6-e4c978a0bef5/volumes/kubernetes.io~csi/pvc-719c8ef2-5bdb-4638-b4db-7d59b53d21f0/mount does not exist'
Warning: config file does not have fips_mode_enabled item in section mount.. You should be able to find a new config file in the same folder as current config file /etc/amazon/efs/efs-utils.conf. Consider update the new config file to latest config file. Use the default value [fips_mode_enabled = False].Warning: config file does not have retry_nfs_mount_command item in section mount.. You should be able to find a new config file in the same folder as current config file /etc/amazon/efs/efs-utils.conf. Consider update the new config file to latest config file. Use the default value [retry_nfs_mount_command = True].
  Warning  FailedMount  3m33s (x6 over 23m)  kubelet  MountVolume.SetUp failed for volume "pvc-719c8ef2-5bdb-4638-b4db-7d59b53d21f0" : rpc error: code = DeadlineExceeded desc = context deadline exceeded
```

'Cannot connect to file system mount target ip address x.x.x.x.' 및 'Connection to the mount target IP address x.x.x.x timeout' 메시지를 볼 수 있습니다. 이는 EFS 파일 시스템이 Pod에 마운트되지 못하고 있음을 나타냅니다.

### 3단계: 노드 네트워킹 구성 확인

Pod가 스케줄된 노드의 네트워킹 구성을 확인해 봅시다.

```bash
$ export NODE=`kubectl get pod $POD -o jsonpath='{.spec.nodeName}'`
$ export INSTANCE=`kubectl get node $NODE -o jsonpath='{.spec.providerID}' | cut -d'/' -f5`
$ export SG=`aws ec2 describe-instances --instance-ids $INSTANCE --query "Reservations[].Instances[].SecurityGroups[].GroupId" --output text`
$ aws ec2 describe-security-groups --group-ids $SG --query "SecurityGroups[].IpPermissionsEgress[]"
[
    {
        "IpProtocol": "-1",
        "UserIdGroupPairs": [],
        "IpRanges": [
            {
                "CidrIp": "0.0.0.0/0"
            }
        ],
        "Ipv6Ranges": [],
        "PrefixListIds": []
    }
]
```

아웃바운드 규칙에는 제한이 없습니다. IpProtocol -1은 모든 프로토콜을 나타내고 CidrIp는 대상을 0.0.0.0/0으로 나타냅니다. 따라서 워커 노드에서의 통신은 제한되지 않으며 EFS 마운트 대상에 도달할 수 있어야 합니다.

:::info
EKS 콘솔에서도 이를 확인할 수 있습니다. eks-workshop 클러스터로 이동하여 efs-app Pod와 노드의 인스턴스 ID를 찾습니다. 보안 그룹은 이 인스턴스의 EC2 콘솔에서 찾을 수 있습니다.
<ConsoleButton
  url="https://us-west-2.console.aws.amazon.com/eks/home?region=us-west-2#/clusters/eks-workshop"
  service="eks"
  label="Open EKS Console Tab"
/>
:::

### 4단계: EFS 파일 시스템 네트워킹 구성 확인

이제 EFS 파일 시스템 네트워킹 구성을 확인해 봅시다.

```bash
$ export AZ=`aws ec2 describe-instances --instance-ids $INSTANCE --query "Reservations[*].Instances[*].[Placement.AvailabilityZone]" --output text`
$ export EFS=`kubectl get pv $(kubectl get pvc efs-claim -o jsonpath='{.spec.volumeName}') -o jsonpath='{.spec.csi.volumeHandle}' | cut -d':' -f1`
$ export MT_ENI=`aws efs describe-mount-targets --file-system-id $EFS --query "MountTargets[*].[NetworkInterfaceId]" --output text`
$ export MT_SG=`aws ec2 describe-network-interfaces --network-interface-ids $MT_ENI --query "NetworkInterfaces[*].[Groups[*].GroupId]" --output text`
$ export MT_SG_UNIQUE=$(echo $MT_SG | xargs -n1 | sort -u | xargs)
$ aws ec2 describe-security-groups --group-ids $MT_SG_UNIQUE --query "SecurityGroups[].IpPermissions[]"
[
    {
        "IpProtocol": "tcp",
        "FromPort": 80,
        "ToPort": 80,
        "UserIdGroupPairs": [],
        "IpRanges": [
            {
                "CidrIp": "10.42.0.0/16"
            }
        ],
        "Ipv6Ranges": [],
        "PrefixListIds": []
    }
]
```

EFS의 마운트 대상에 연결된 보안 그룹에는 VPC CIDR에서 포트 80에 대한 인바운드 규칙만 있습니다. 마운트 대상의 보안 그룹은 포트 2049에서 트래픽을 허용해야 합니다.

:::info
EFS 콘솔에서도 이를 확인할 수 있습니다. eks-workshop-efs라는 이름의 EFS 파일 시스템 ID를 클릭합니다. 그런 다음 Network를 클릭하여 모든 가용 영역의 마운트 대상과 각 마운트 대상에 연결된 보안 그룹을 확인합니다.

<ConsoleButton
  url="https://us-west-2.console.aws.amazon.com/efs/home?region=us-west-2#/file-systems"
  service="efs"
  label="Open EFS Console Tab"
/>
:::

### 5단계: EFS 마운트 대상 보안 그룹에 인바운드 규칙 추가

EFS 마운트 대상 보안 그룹에 인바운드 규칙을 추가하여 EKS 클러스터의 VPC CIDR에서 포트 2049의 NFS 트래픽을 허용하도록 합시다.

```bash
$ export VPC_ID=`aws eks describe-cluster --name ${EKS_CLUSTER_NAME} --query "cluster.resourcesVpcConfig.vpcId" --output text`
$ export CIDR=`aws ec2 describe-vpcs --vpc-ids $VPC_ID --query "Vpcs[*].CidrBlock" --output text`
$ for sg_id in $MT_SG_UNIQUE; do
$    echo "Adding ingress rule to security group: $sg_id"
$    aws ec2 authorize-security-group-ingress --group-id "$sg_id" --protocol tcp --port 2049 --cidr "$CIDR"
$  done
{
    "Return": true,
    "SecurityGroupRules": [
        {
            "SecurityGroupRuleId": "sgr-05ae66b3cfafxxxxx",
            "GroupId": "sg-0d69452207dbxxxxx",
            "GroupOwnerId": "682844965773",
            "IsEgress": false,
            "IpProtocol": "tcp",
            "FromPort": 2049,
            "ToPort": 2049,
            "CidrIpv4": "10.42.0.0/16"
        }
    ]
}
```

3-4분 후에 default 네임스페이스의 Pod가 실행 상태임을 확인할 수 있습니다.

```bash timeout=600 hook=fix-3 hookTimeout=600 wait=60
$ kubectl rollout restart deploy/efs-app
$ sleep 120
$ kubectl get pods -l app=efs-app
NAME                       READY   STATUS    RESTARTS   AGE
efs-app-5c4df89785-m4qz4   1/1     Running   0          102m
```

EFS 마운트 대상 보안 그룹이 포트 2049에서 트래픽을 허용하므로 워커 노드가 마운트 대상과 성공적으로 통신하고 Pod에 EFS 마운트를 완료할 수 있었습니다.

## 마무리

볼륨 마운트 문제로 인해 ContainerCreating 상태에서 멈춰 있는 Pod의 문제를 해결하려면:

- Pod에서 사용하는 볼륨 클레임을 확인하고 사용된 볼륨 유형을 식별합니다.
- 해당 볼륨에 사용되는 CSI 드라이버를 찾고 [EKS Storage](https://docs.aws.amazon.com/eks/latest/userguide/storage.html) 문서에서 요구 사항을 확인합니다.
- 해당 스토리지 유형 문서에 언급된 모든 요구 사항이 충족되는지 확인합니다.
- [EFS CSI Driver](https://repost.aws/knowledge-center/eks-troubleshoot-efs-volume-mount-issues) 문제 해결 가이드를 따릅니다.

