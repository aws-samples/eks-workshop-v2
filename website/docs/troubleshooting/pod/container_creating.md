---
title: "PodStuck - ContainerCreating"
sidebar_position: 73
---

In this section, we will learn how to troubleshoot a pod that is stuck in the ContainerCreating state. Now let's verify if the deployment is created, so we can start troubleshooting the scenario.

```bash
$ kubectl get deploy efs-app -n default
NAME      READY   UP-TO-DATE   AVAILABLE   AGE
efs-app   0/1     1            0           18m
```

:::info
If you get the same output, it means you are ready to start the troubleshooting.
:::

The task for you in this troubleshooting section is to find the cause for the deployment efs-app to be in 0/1 ready state and to fix it, so that the deployment will have one pod ready and running.

## Let's start the troubleshooting

### Step 1: Verify pod status

First, we need to verify the status of our pod.

```bash
$ kubectl get pods -l app=efs-app
NAME                       READY   STATUS              RESTARTS   AGE
efs-app-5c4df89785-m4qz4   0/1     ContainerCreating   0          19m
```

### Step 2: Describe the pod

You can see that the pod status is showing as ContainerCreating. Let's describe the pod to see the events.

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

We can see 'Cannot connect to file system mount target ip address x.x.x.x.' and 'Connection to the mount target IP address x.x.x.x timeout' messages. This suggests that the EFS file system is failing to mount on the pod.

### Step 3: Check node networking configuration

Let's check the networking configuration of the node where the pod is scheduled.

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

The egress rules have no limitations. IpProtocol -1 indicates all protocols and the CidrIp indicates the destination as 0.0.0.0/0. So the communication from the worker node is not restricted and should be able to reach the EFS mount target.

:::info
You can also check this in the EKS Console. Navigate to eks-workshop cluster, find the efs-app pod and the node's instance id. The security groups can be found from the ec2 console for this instance.
<ConsoleButton
  url="https://us-west-2.console.aws.amazon.com/eks/home?region=us-west-2#/clusters/eks-workshop"
  service="eks"
  label="Open EKS Console Tab"
/>
:::

### Step 4: Check EFS file system networking configuration

Now, let's check the EFS file system networking configuration.

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

The security group attached to the mount target of EFS has inbound rules only on port 80 from the VPC CIDR. The security group of mount target should allow traffic on port 2049.

:::info
You can also check this in EFS console. Click on EFS file system Id named eks-workshop-efs. Then click on Network to view mount targets for all availability zones and the security groups attached to each mount target.

<ConsoleButton
  url="https://us-west-2.console.aws.amazon.com/efs/home?region=us-west-2#/file-systems"
  service="efs"
  label="Open EFS Console Tab"
/>
:::

### Step 5: Add inbound rule to EFS mount target security group

Let's add the inbound rule to EFS mount target security group to allow NFS traffic on port 2049 from VPC CIDR of the EKS cluster.

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


After 3-4 minutes, you should notice that the pod in default namespace is in running state

```bash timeout=600 hook=fix-3 hookTimeout=600
$ kubectl rollout restart deploy/efs-app
$ sleep 120
$ kubectl get pods -l app=efs-app
NAME                       READY   STATUS    RESTARTS   AGE
efs-app-5c4df89785-m4qz4   1/1     Running   0          102m
```

Since the EFS mount target security group allow traffic on port 2049 the worker nodes were able to successfully communicate with the mount targets and complete the mount of EFS to the pods.

## Wrapping it up

To troubleshooting pods stuck in ContainerCreating state due to volume mount issues:

- Check the volume claim used by the pod and identify the type of volume used.
- Find the CSI driver used for that volume and check the requirements on the [EKS Storage](https://docs.aws.amazon.com/eks/latest/userguide/storage.html) documents.
- Confirm that all the requirements mentioned in the corresponding storage type document are met.
- Follow the troubleshooting guide of [EFS CSI Driver](https://repost.aws/knowledge-center/eks-troubleshoot-efs-volume-mount-issues)
