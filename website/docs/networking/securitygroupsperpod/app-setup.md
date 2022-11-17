---
title: "Application Setup"
sidebar_position: 70
weight: 70
---

### 1. Create Namespace

Create a namespace to deploy resources to:

```bash
$ kubectl create namespace sg-per-pod
```

### 2. Deploy SecurityGroupPolicy

Create a policy file named `my-security-group-policy.yaml` with the following command:

```bash
$ cat >my-security-group-policy.yaml <<EOF
apiVersion: vpcresources.k8s.aws/v1beta1
kind: SecurityGroupPolicy
metadata:
  name: my-security-group-policy
  namespace: sg-per-pod
spec:
  podSelector: 
    matchLabels:
      role: my-role
  securityGroups:
    groupIds:
      - ${POD_SG}
EOF
```

The command reads the expored `POD_SG` values for the security group ID that’ll be attached to the application pod.

### 3. Create Secret for RDS

Before deploying our two pods we need to provide them with the RDS endpoint and password. We will create a kubernetes secret.

```bash
$ kubectl create secret generic rds \
--namespace=sg-per-pod \
--from-literal="password=${NETWORKING_RDS_PASSWORD}" \
--from-literal="host=${NETWORKING_RDS_ENDPOINT}"
```

To verify the secret:

```bash
$ kubectl -n sg-per-pod describe secret rds
```

The expected output is:

```text
Name:         rds
Namespace:    sg-per-pod
Labels:       <none>
Annotations:  <none>

Type:  Opaque

Data
====
host:      56 bytes
password:  32 bytes
```

### 4. Deploy Broken Pod

As we saw that the `Security Group Policy`, we defined earlier, only applies to pods with label `app: green-pod` , the manifest `red-pod.yaml` does not contain that label and hence would not get the correct security group, resulting in no communication with the database. List the manifest and observe the labels specified.

Let’s deploy the pod with the incorrect labels:

```bash
$ kubectl apply -f https://www.eksworkshop.com/beginner/115_sg-per-pod/deployments.files/red-pod.yaml
```

Let’s take a look at the pod logs now:

```bash
$ export RED_POD_NAME=$(kubectl -n sg-per-pod get pods -l app=red-pod -o jsonpath='{.items[].metadata.name}')

$ kubectl -n sg-per-pod  logs -f ${RED_POD_NAME}
```

The output expected is:

```text
Database connection failed due to timeout expired
```

### 5. Deploy Working Pod

The manifest `green-pod.yaml`, contains the correct labels for the security group policy and should be able to communicate with the database. Let’s deploy the app:

```bash
$ kubectl apply -f https://www.eksworkshop.com/beginner/115_sg-per-pod/deployments.files/green-pod.yaml
```

Let’s take a look at the pod logs now:

```bash
$ export GREEN_POD_NAME=$(kubectl -n sg-per-pod get pods -l app=green-pod -o jsonpath='{.items[].metadata.name}')

$ kubectl -n sg-per-pod  logs -f ${GREEN_POD_NAME}
```

The output expected is:

```text
[('--------------------------',), ('Welcome to the eksworkshop',), ('--------------------------',)]
[('--------------------------',), ('Welcome to the eksworkshop',), ('--------------------------',)]
```

Another verification we can perform is the ENI attached to the pod and then verify the associated security group in the AWS console. The following command produces the ENI ID from the pod annotations:

```bash
$ kubectl -n sg-per-pod  describe pod $GREEN_POD_NAME | head -11
```

The outuput should be similar to:

```text
Name:         green-pod-5c786d8dff-4kmvc
Namespace:    sg-per-pod
Priority:     0
Node:         ip-192-168-33-222.us-east-1.compute.internal/192.168.33.222
Start Time:   Thu, 03 Dec 2020 05:25:54 +0000
Labels:       app=green-pod
              pod-template-hash=5c786d8dff
Annotations:  kubernetes.io/psp: eks.privileged
              vpc.amazonaws.com/pod-eni:
                [{"eniId":"eni-0d8a3a3a7f2eb57ab","ifAddress":"06:20:0d:3c:5f:bc","privateIp":"192.168.47.64","vlanId":1,"subnetCidr":"192.168.32.0/19"}]
Status:       Running
```

Follow [this link](https://console.aws.amazon.com/ec2/home?#NIC:search=POD_SG) to locate the ENI in the AWS console. The console should show the name of the security group attached to the ENI, like the following screen shot.

![Insights](/img/networking/securitygroupsperpod/eni-sg.jpg)

This setup verifies the attached security group.
