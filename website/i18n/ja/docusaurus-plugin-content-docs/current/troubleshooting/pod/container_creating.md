---
title: "PodStuck - ContainerCreating"
sidebar_position: 73
kiteTranslationSourceHash: ca6702af7a03ccc3060495f71996fd4e
---

このセクションでは、ContainerCreating状態で停止しているポッドのトラブルシューティング方法について学びます。まず、デプロイメントが作成されているかを確認して、トラブルシューティングのシナリオを開始しましょう。

```bash
$ kubectl get deploy efs-app -n default
NAME      READY   UP-TO-DATE   AVAILABLE   AGE
efs-app   0/1     1            0           18m
```

:::info
同じ出力が得られた場合、トラブルシューティングを開始する準備ができています。
:::

このトラブルシューティングセクションでの課題は、デプロイメントefs-appが0/1レディ状態になっている原因を見つけ、それを修正してデプロイメントに1つのポッドが準備完了して実行されるようにすることです。

## トラブルシューティングを始めましょう

### ステップ1：ポッドの状態を確認する

まず、ポッドの状態を確認する必要があります。

```bash
$ kubectl get pods -l app=efs-app
NAME                       READY   STATUS              RESTARTS   AGE
efs-app-5c4df89785-m4qz4   0/1     ContainerCreating   0          19m
```

### ステップ2：ポッドを詳細に調べる

ポッドの状態がContainerCreatingと表示されています。イベントを確認するためにポッドを詳細に調べてみましょう。

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

「Cannot connect to file system mount target ip address x.x.x.x.」と「Connection to the mount target IP address x.x.x.x timeout」というメッセージが表示されています。これは、EFSファイルシステムがポッドにマウントできないことを示しています。

### ステップ3：ノードのネットワーク設定を確認する

ポッドがスケジュールされているノードのネットワーク設定を確認してみましょう。

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

出力ルールに制限はありません。IpProtocol -1はすべてのプロトコルを示し、CidrIpは宛先が0.0.0.0/0であることを示します。したがって、ワーカーノードからの通信に制限はなく、EFSマウントターゲットに到達できるはずです。

:::info
EKSコンソールでも確認できます。eks-workshopクラスターに移動し、efs-appポッドとノードのインスタンスIDを見つけます。このインスタンスのセキュリティグループはEC2コンソールで確認できます。
<ConsoleButton
  url="https://us-west-2.console.aws.amazon.com/eks/home?region=us-west-2#/clusters/eks-workshop"
  service="eks"
  label="EKSコンソールタブを開く"
/>
:::

### ステップ4：EFSファイルシステムのネットワーク設定を確認する

次に、EFSファイルシステムのネットワーク設定を確認しましょう。

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

EFSのマウントターゲットに関連付けられたセキュリティグループは、VPC CIDRからのポート80のみの受信ルールを持っています。マウントターゲットのセキュリティグループはポート2049のトラフィックを許可する必要があります。

:::info
これはEFSコンソールでも確認できます。eks-workshop-efsという名前のEFSファイルシステムIDをクリックしてください。その後、「ネットワーク」をクリックして、すべてのアベイラビリティゾーンのマウントターゲットと各マウントターゲットに関連付けられたセキュリティグループを表示します。

<ConsoleButton
  url="https://us-west-2.console.aws.amazon.com/efs/home?region=us-west-2#/file-systems"
  service="efs"
  label="EFSコンソールタブを開く"
/>
:::

### ステップ5：EFSマウントターゲットのセキュリティグループに受信ルールを追加する

EKSクラスターのVPC CIDRからポート2049でNFSトラフィックを許可するために、EFSマウントターゲットのセキュリティグループに受信ルールを追加しましょう。

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

3〜4分後、defaultネームスペースのポッドが実行状態になっていることに気付くでしょう。

```bash timeout=600 hook=fix-3 hookTimeout=600 wait=60
$ kubectl rollout restart deploy/efs-app
$ sleep 120
$ kubectl get pods -l app=efs-app
NAME                       READY   STATUS    RESTARTS   AGE
efs-app-5c4df89785-m4qz4   1/1     Running   0          102m
```

EFSマウントターゲットのセキュリティグループがポート2049のトラフィックを許可するようになったため、ワーカーノードはマウントターゲットと正常に通信し、EFSをポッドにマウントすることができました。

## まとめ

ボリュームマウントの問題によりContainerCreating状態で停止しているポッドのトラブルシューティングには：

- ポッドが使用しているボリュームクレームを確認し、使用しているボリュームの種類を特定します。
- そのボリュームに使用されているCSIドライバーを見つけ、[EKS Storage](https://docs.aws.amazon.com/eks/latest/userguide/storage.html)ドキュメントの要件を確認します。
- 対応するストレージタイプのドキュメントに記載されているすべての要件が満たされていることを確認します。
- [EFS CSIドライバー](https://repost.aws/knowledge-center/eks-troubleshoot-efs-volume-mount-issues)のトラブルシューティングガイドに従います。
