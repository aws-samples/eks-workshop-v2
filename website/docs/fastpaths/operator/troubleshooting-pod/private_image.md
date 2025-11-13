---
title: "ImagePullBackOff - ECR Private Image"
sidebar_position: 71
---

In this section we will learn how to troubleshoot the pod ImagePullBackOff error for a ECR private image. Now let's verify if the deployment is created, so we can start troubleshooting the scenario.

```bash
$ kubectl get deploy ui-private -n default
NAME         READY   UP-TO-DATE   AVAILABLE   AGE
ui-private   0/1     1            0           4m25s
```

:::info
If you get the same output, it means you are ready to start the troubleshooting.
:::

The task for you in this troubleshooting section is to find the cause for the deployment ui-private to be in 0/1 ready state and to fix it, so that the deployment will have one pod ready and running.

## Let's start the troubleshooting

### Step 1: Check pod status

First, we need to verify the status of our pods.

```bash
$ kubectl get pods -l app=app-private
NAME                          READY   STATUS             RESTARTS   AGE
ui-private-7655bf59b9-jprrj   0/1     ImagePullBackOff   0          4m42s
```

### Step 2: Describe the pod

You can see that the pod status is showing as ImagePullBackOff. Let's describe the pod to see the events.

```bash expectError=true
$ POD=`kubectl get pods -l app=app-private -o jsonpath='{.items[*].metadata.name}'`
$ kubectl describe pod $POD | awk '/Events:/,/^$/'
Events:
  Type     Reason     Age                    From               Message
  ----     ------     ----                   ----               -------
  Normal   Scheduled  5m15s                  default-scheduler  Successfully assigned default/ui-private-7655bf59b9-jprrj to ip-10-42-33-232.us-west-2.compute.internal
  Normal   Pulling    3m53s (x4 over 5m15s)  kubelet            Pulling image "1234567890.dkr.ecr.us-west-2.amazonaws.com/retail-sample-app-ui:1.2.1"
  Warning  Failed     3m53s (x4 over 5m14s)  kubelet            Failed to pull image "1234567890.dkr.ecr.us-west-2.amazonaws.com/retail-sample-app-ui:1.2.1": failed to pull and unpack image "1234567890.dkr.ecr.us-west-2.amazonaws.com/retail-sample-app-ui:1.2.1": failed to resolve reference "1234567890.dkr.ecr.us-west-2.amazonaws.com/retail-sample-app-ui:1.2.1": unexpected status from HEAD request to https:/"1234567890.dkr.ecr.us-west-2.amazonaws.com/v2/retail-sample-app-ui/manifests/1.2.1: 403 Forbidden
  Warning  Failed     3m53s (x4 over 5m14s)  kubelet            Error: ErrImagePull
  Warning  Failed     3m27s (x6 over 5m14s)  kubelet            Error: ImagePullBackOff
  Normal   BackOff    4s (x21 over 5m14s)    kubelet            Back-off pulling image "1234567890.dkr.ecr.us-west-2.amazonaws.com/retail-sample-app-ui:1.2.1"
```

From the events of the pod, we can see the 'Failed to pull image' warning, with cause as 403 Forbidden. This indicates that the kubelet faced access denied while trying to pull the image used in the deployment. Let's get the URI of the image used in the deployment.

```bash
$ kubectl get deploy ui-private -o jsonpath='{.spec.template.spec.containers[*].image}'
"1234567890.dkr.ecr.us-west-2.amazonaws.com/retail-sample-app-ui:1.2.1"
```

### Step 3: Check the image reference

From the image URI, the image is referenced from the account where our EKS cluster is in. Let's check the ECR repository to see if any such image exists.

```bash
$ aws ecr describe-images --repository-name retail-sample-app-ui --image-ids imageTag=1.2.1
{
    "imageDetails": [
        {
            "registryId": "1234567890",
            "repositoryName": "retail-sample-app-ui",
            "imageDigest": "sha256:b338785abbf5a5d7e0f6ebeb8b8fc66e2ef08c05b2b48e5dfe89d03710eec2c1",
            "imageTags": [
                "1.2.1"
            ],
            "imageSizeInBytes": 268443135,
            "imagePushedAt": "2024-10-11T14:03:01.207000+00:00",
            "imageManifestMediaType": "application/vnd.docker.distribution.manifest.v2+json",
            "artifactMediaType": "application/vnd.docker.container.image.v1+json"
        }
    ]
}
```

The image path we have in deployment i.e. account_id.dkr.ecr.us-west-2.amazonaws.com/retail-sample-app-ui:1.2.1 have a valid registryId i.e. account-number, valid repositoryName i.e. "retail-sample-app-ui" and valid imageTag i.e. "1.2.1". Which confirms the path of the image is correct and is not a wrong reference.

:::info
Alternatively, you can also check from the ECR console. Click the button below to open the ECR Console. Then click on retail-sample-app-ui repository and the image tag 1.2.1.
<ConsoleButton
  url="https://us-west-2.console.aws.amazon.com/ecr/private-registry/repositories?region=us-west-2"
  service="ecr"
  label="Open ECR Console Tab"
/>
:::

### Step 4: Check kubelet permissions

As we confirmed that the image URI is correct, let's check the permissions of the kubelet and see if the permissions required to pull images from ECR exists.

Get the IAM role attached to worker nodes in the managed node group of the cluster and list the IAM policies attached to the role.

```bash
$ ROLE_NAME=`aws eks describe-nodegroup --cluster-name $EKS_CLUSTER_NAME --nodegroup-name default --query 'nodegroup.nodeRole' --output text | cut -d'/' -f2`
$ aws iam list-attached-role-policies --role-name $ROLE_NAME
{
    "AttachedPolicies": [
        {
            "PolicyName": "AmazonSSMManagedInstanceCore",
            "PolicyArn": "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
        },
        {
            "PolicyName": "AmazonEC2ContainerRegistryReadOnly",
            "PolicyArn": "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
        },
        {
            "PolicyName": "AmazonEKSWorkerNodePolicy",
            "PolicyArn": "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
        },
        {
            "PolicyName": "AmazonSSMPatchAssociation",
            "PolicyArn": "arn:aws:iam::aws:policy/AmazonSSMPatchAssociation"
        }
    ]
}
```

The AWS managed policy "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly" is attached to the worker node role and this policy should provide enough permissions to pull a Image from ECR private repository.

### Step 5: Check ECR repo permissions

The permissions to the ECR repository can be managed at both Identity and Resource level. The Identity level permissions are provided at IAM and the resource level permissions are provided at the repository level. As we confirmed that identity based permissions are good, let's the check the policy for ECR repo.

```bash
$ aws ecr get-repository-policy --repository-name retail-sample-app-ui --query policyText --output text | jq .
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "new policy",
      "Effect": "Deny",
      "Principal": {
        "AWS": "arn:aws:iam::1234567890:role/EksNodeGroupRole"
      },
      "Action": [
        "ecr:UploadLayerPart",
        "ecr:SetRepositoryPolicy",
        "ecr:PutImage",
        "ecr:ListImages",
        "ecr:InitiateLayerUpload",
        "ecr:GetRepositoryPolicy",
        "ecr:GetDownloadUrlForLayer",
        "ecr:DescribeRepositories",
        "ecr:DeleteRepositoryPolicy",
        "ecr:DeleteRepository",
        "ecr:CompleteLayerUpload",
        "ecr:BatchGetImage",
        "ecr:BatchDeleteImage",
        "ecr:BatchCheckLayerAvailability"
      ]
    }
  ]
}
```

The ECR repository policy has Effect as Deny and the Principal as the EKS managed node role. Which is restricting the kubelet from pulling images in this repository. Let's change the effect to allow and see if the kubelet is able to pull the image.

:::note
We will be using below json file to modify the ECR repository permissions.

```json {6}
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "new policy",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::1234567890:role/EksNodeGroupRole"
      },
      "Action": [
        "ecr:UploadLayerPart",
        "ecr:SetRepositoryPolicy",
        "ecr:PutImage",
        "ecr:ListImages",
        "ecr:InitiateLayerUpload",
        "ecr:GetRepositoryPolicy",
        "ecr:GetDownloadUrlForLayer",
        "ecr:DescribeRepositories",
        "ecr:DeleteRepositoryPolicy",
        "ecr:DeleteRepository",
        "ecr:CompleteLayerUpload",
        "ecr:BatchGetImage",
        "ecr:BatchDeleteImage",
        "ecr:BatchCheckLayerAvailability"
      ]
    }
  ]
}
```

:::

```bash
$ export ROLE_ARN=`aws eks describe-nodegroup --cluster-name ${EKS_CLUSTER_NAME} --nodegroup-name default --query 'nodegroup.nodeRole'`
$ echo '{"Version":"2012-10-17","Statement":[{"Sid":"new policy","Effect":"Allow","Principal":{"AWS":'${ROLE_ARN}'},"Action":["ecr:BatchCheckLayerAvailability","ecr:BatchDeleteImage","ecr:BatchGetImage","ecr:CompleteLayerUpload","ecr:DeleteRepository","ecr:DeleteRepositoryPolicy","ecr:DescribeRepositories","ecr:GetDownloadUrlForLayer","ecr:GetRepositoryPolicy","ecr:InitiateLayerUpload","ecr:ListImages","ecr:PutImage","ecr:SetRepositoryPolicy","ecr:UploadLayerPart"]}]}' > ~/ecr-policy.json
$ aws ecr set-repository-policy --repository-name retail-sample-app-ui --policy-text file://~/ecr-policy.json
```

### Step 6: Restart the deployment and verify the pod status

Now, restart the deployment and check if the pods are running.

```bash timeout=180 hook=fix-2 hookTimeout=600 wait=20
$ kubectl rollout restart deploy ui-private
$ kubectl get pods -l app=app-private
NAME                          READY   STATUS    RESTARTS   AGE
ui-private-7655bf59b9-s9pvb   1/1     Running   0          65m
```

## Wrapping it up

General troubleshooting workflow of the pod with ImagePullBackOff on private image includes:

- Check the pod events for a clue on cause of the issue such as "not found", "access denied" or "timeout".
- If "not found", ensure that the image exists in the path referenced in the private ECR repositories.
- For "access denied", check the permissions on worker node role and the ECR repository policy.
- For timeout on ECR, ensure that the worker node is configured to reach the ECR endpoint.

## Additional Resources

- [ECR on EKS](https://docs.aws.amazon.com/AmazonECR/latest/userguide/ECR_on_EKS.html)
- [ECR Repository Policies](https://docs.aws.amazon.com/AmazonECR/latest/userguide/repository-policies.html)
- [EKS Networking](https://docs.aws.amazon.com/eks/latest/userguide/eks-networking.html)
