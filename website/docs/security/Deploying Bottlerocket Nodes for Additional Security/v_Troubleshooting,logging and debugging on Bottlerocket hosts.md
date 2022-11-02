---
title: "Troubleshooting,logging and debugging on Bottlerocket hosts"
sidebar_position: 50
---

Bottlerocket has a control container enabled by default that runs on a separate instance of containerd. This container runs the [AWS SSM agent](https://github.com/aws/amazon-ssm-agent) and enables you to run commands or start interactive shell sessions on Bottlerocket nodes. Choose one of the instances and launch an SSM session:

```bash
$ aws ssm start-session --target instance-id

#replace the instance-id with your own instance id

Starting session with SessionId: eks-course-0bf27ea1e078f5c40
Welcome to Bottlerocket's control container!
```
You are now connected to the Bottlerocket [“control” container](https://github.com/bottlerocket-os/bottlerocket-control-container). To replace this control container with your own, refer to the [documentation](https://github.com/bottlerocket-os/bottlerocket#settings). In order to access the container through SSM, you need to give the node the appropriate IAM role. Amazon EKS will handle this for you when using a managed node group. Once you have access to the control container, you can execute commands, which in turn make the appropriate API calls to a local service running on the instance to configure and manage your Bottlerocket node. This is not a complete shell environment and you have a limited set of commands available.

The [Bottlerocket API](https://github.com/bottlerocket-os/bottlerocket#api) includes methods for checking and starting system updates. You can read more about the update APIs in the [update system documentation](https://github.com/bottlerocket-os/bottlerocket/blob/develop/sources/updater/README.md#update-api). Most of your interactions will be through the [apiclient](https://github.com/bottlerocket-os/bottlerocket/tree/develop/sources/api/apiclient) command. You can find more details in the [documentation](https://github.com/bottlerocket-os/bottlerocket#settings). The apiclient knows how to handle those update APIs for you. You can also use apiclient to describe the configuration setting on your instance.

```bash
$ apiclient -u /settings
```

We can view key details in its output, such as the node IP address, DNS settings, the motd content, and update URLs. You will also see that the admin container is enabled as we have configured SSH while creating the cluster.

Connect to an instance:

Bottlerocket also has an “administrative” container, which is disabled by default and also runs on its own containerd instance on the host. This container has an SSH server running that allows you to log in as ec2-user using your EC2-registered SSH key.

In a terminal window, use the ssh command to connect to the instance. Specify the path and file name of the private key (.pem), and use the public IP from the previous step. To connect to your instance, enter the following command.

```bash
$ ssh -i ~/.ssh/eks_bottlerocket.pem ec2-user@BottlerocketElasticIP
```
Once inside the admin container, execute sheltie to get a complete root shell into the Bottlerocket instance. You can then invoke other administrative commands. For example, you can collect a set of logs.

```bash
$ sudo sheltie
$ logdog
```

This will create a log archive /var/log/support/bottlerocket-logs.tar.gz. You may retrieve the file through SSH. Once you’ve quit the Bottlerocket host, execute the following command:

```bash
$ ssh -i ~/.ssh/eks_bottlerocket.pem \
    ec2-user@BottlerocketElasticIP \
    "cat /.bottlerocket/rootfs/var/log/support/bottlerocket-logs.tar.gz" > bottlerocket-logs.tar.gz
```
