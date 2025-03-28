---
title: "Connect Hybrid Node"
sidebar_position: 10
sidebar_custom_props: { "module": false }
weight: 20 # used by test framework
---

Amazon EKS Hybrid Nodes use temporary IAM credentials provisioned by AWS SSM
hybrid activations or AWS IAM Roles Anywhere to authenticate with the Amazon EKS
cluster. In this workshop, we will use SSM hybrid activations.

To create hybrid activation and populate the `ACTIVATION_ID` and `ACTIVATION_CODE`
environment variables, run the following commands:

```bash timeout=300 wait=30
$ export ACTIVATION_JSON=$(aws ssm create-activation \
--default-instance-name hybrid-ssm-node \
--iam-role $HYBRID_ROLE_NAME \
--registration-limit 1 \
--region $AWS_REGION)
$ export ACTIVATION_ID=$(echo $ACTIVATION_JSON | jq -r ".ActivationId")
$ export ACTIVATION_CODE=$(echo $ACTIVATION_JSON | jq -r ".ActivationCode")
```

With our activation created, we can now create a `nodeconfig.yaml` which will be
referenced when we join our instance to the cluster. This utilizes the SSM
`ACTIVATION_CODE` and `ACTIVATION_ID` created in the previous step as well as
the `EKS_CLUSTER_NAME` name and `AWS_REGION` environment variables.

::yaml{file="manifests/modules/networking/eks-hybrid-nodes/nodeconfig.yaml"}

```bash
$ cat ~/environment/eks-workshop/modules/networking/eks-hybrid-nodes/nodeconfig.yaml \
| envsubst > nodeconfig.yaml
```

Let's copy `nodeconfig.yaml` over to our hybrid node instance.

```bash timeout=300 wait=30
$ mkdir -p ~/.ssh/
$ ssh-keyscan -H $HYBRID_NODE_IP &> ~/.ssh/known_hosts
$ scp -i private-key.pem nodeconfig.yaml ubuntu@$HYBRID_NODE_IP:/home/ubuntu/nodeconfig.yaml
```

Next, let's install the hybrid nodes dependencies using `nodeadm` on our EC2 instance. This includes containerd, kubelet, kubectl, and AWS SSM or AWS IAM Roles Anywhere components. See hybrid nodes [nodeadm reference](https://docs.aws.amazon.com/eks/latest/userguide/hybrid-nodes-nodeadm.html) for more information on the components and file locations installed by `nodeadm install`.

```bash timeout=300 wait=30
$ ssh -i private-key.pem ubuntu@$HYBRID_NODE_IP \
"sudo nodeadm install $EKS_CLUSTER_VERSION --credential-provider ssm"
```

With our dependencies installed, and our `nodeconfig.yaml` in place, we initialize the instance as a hybrid node.

```bash timeout=300 wait=30
$ ssh -i private-key.pem ubuntu@$HYBRID_NODE_IP \
"sudo nodeadm init -c file://nodeconfig.yaml"
```

Lets see if our hybrid node has joined the cluster successfully. Our hybrid node will have the prefix `mi-` because we used Systems Manager for our credential provider.

```bash timeout=300 wait=30
$ kubectl get nodes
NAME                                          STATUS     ROLES    AGE    VERSION
ip-10-42-118-191.us-west-2.compute.internal   Ready      <none>   1h   v1.31.3-eks-59bf375
ip-10-42-154-9.us-west-2.compute.internal     Ready      <none>   1h   v1.31.3-eks-59bf375
ip-10-42-163-120.us-west-2.compute.internal   Ready      <none>   1h   v1.31.3-eks-59bf375
mi-015a9aae5526e2192                          NotReady   <none>   5m     v1.31.4-eks-aeac579
```

Great! The node appears but with a `NotReady` status. This is because we must install a CNI for hybrid nodes to become ready to serve workloads. So, let us first add the Cilium Helm repo.

```bash timeout=300 wait=30
$ helm repo add cilium https://helm.cilium.io/
```

With the repo added, we can install Cilium using the configuration provided below.

```bash timeout=300 wait=30
$ helm install cilium cilium/cilium \
--version 1.17.1 \
--namespace cilium \
--create-namespace \
--values ~/environment/eks-workshop/modules/networking/eks-hybrid-nodes/cilium-values.yaml
```

::yaml{file="manifests/modules/networking/eks-hybrid-nodes/cilium-values.yaml"}

After installing Cilium our Hybrid Node should come up, happy and healthy.

```bash timeout=300 wait=30
$ kubectl wait --for=condition=Ready nodes --all --timeout=2m
NAME                                          STATUS     ROLES    AGE    VERSION
ip-10-42-118-191.us-west-2.compute.internal   Ready      <none>   1h   v1.31.3-eks-59bf375
ip-10-42-154-9.us-west-2.compute.internal     Ready      <none>   1h   v1.31.3-eks-59bf375
ip-10-42-163-120.us-west-2.compute.internal   Ready      <none>   1h   v1.31.3-eks-59bf375
mi-015a9aae5526e2192                          Ready      <none>   5m   v1.31.4-eks-aeac579
```

That's it! You now have a hybrid node up and running in your cluster.
