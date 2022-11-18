---
title: "Troubleshooting, logging and debugging on Bottlerocket hosts"
sidebar_position: 55
---

The base operating system of bottlerocket has just what you need to run containers reliably, and is built with standard open-source components. Bottlerocket-specific additions focus on reliable updates and on the API. Instead of making configuration changes manually, you can change settings with an API call, and these changes are automatically migrated through updates.

Some notable features include:

- [API](https://github.com/bottlerocket-os/bottlerocket#api) access for configuring your system, with secure out-of-band [access](https://github.com/bottlerocket-os/bottlerocket#exploration) methods when you need them.
- [Updates](https://github.com/bottlerocket-os/bottlerocket#updates) based on partition flips, for fast and reliable system updates.
- [Modeled configuration](https://github.com/bottlerocket-os/bottlerocket#settings) that's automatically migrated through updates.
- [Security](https://github.com/bottlerocket-os/bottlerocket#security) as a top priority.


Bottlerocket has a ["control" container](https://github.com/bottlerocket-os/bottlerocket-control-container), enabled by default, that runs outside of the orchestrator in a separate instance of containerd. This container runs the AWS SSM agent that lets you run commands, or start shell sessions, on Bottlerocket instances in EC2. (You can easily replace this control container with your own just by changing the URI; see Settings.)

If you prefer a command-line tool, you can start a session with a AWS CLI version equal to or greater than aws-cli/2.7.24 and the session-manager-plugin. Then you'd be able to start a session using only your instance ID, like this:

```bash test=false
#To check the currently installed version, use the following command:

$ aws --version

aws-cli/2.7.24 Python/3.8.8 Linux/4.14.133-113.105.amzn2.x86_64 botocore/1.13

$ aws ssm start-session --target instance-id

#replace the instance-id with your own instance id

Starting session with SessionId: eks-course-0bf27ea1e078f5c40
Welcome to Bottlerocket's control container!
```
With the default control container, you can make API calls to configure and manage your Bottlerocket host. To do even more, read the next section about the [admin container](https://github.com/bottlerocket-os/bottlerocket#admin-container). You can access the admin container from the control container like this:

```bash test=false
$ enter-admin-container
```

The “administrative” container is disabled by default and also runs on its own containerd instance on the host. This container has an SSH server running that allows you to log in as ec2-user using your EC2-registered SSH key. We can then run the following commands to drop into root shell in the Bottlerocket host's root filesystem and collect logs.

```bash
$ sudo sheltie
$ logdog
```

