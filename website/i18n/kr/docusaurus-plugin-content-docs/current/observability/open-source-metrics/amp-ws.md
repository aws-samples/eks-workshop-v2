---
title: "AMP를 사용하여 메트릭 저장하기"
sidebar_position: 20
---

Amazon Managed Service for Prometheus 작업 공간이 이미 생성되어 있습니다. 콘솔에서 확인할 수 있어야 합니다:

<ConsoleButton url="https://console.aws.amazon.com/prometheus/home#/workspaces" service="aps" label="APS 콘솔 열기"/>

작업 공간을 보려면 왼쪽 제어 패널에서 **모든 작업 공간** 탭을 클릭하세요. **eks-workshop**으로 시작하는 작업 공간을 선택하면 규칙 관리, 알림 관리자 등 작업 공간 아래의 여러 탭을 볼 수 있습니다.

메트릭이 성공적으로 수집되었는지 확인해 보겠습니다:

```bash
$ awscurl -X POST --region $AWS_REGION --service aps "${AMP_ENDPOINT}api/v1/query?query=up" | jq '.data.result[1]'
{
  "metric": {
    "__name__": "up",
    "account_id": "1234567890",
    "beta_kubernetes_io_arch": "amd64",
    "beta_kubernetes_io_instance_type": "m5.large",
    "beta_kubernetes_io_os": "linux",
    "cluster": "eks-workshop",
    "eks_amazonaws_com_capacityType": "ON_DEMAND",
    "eks_amazonaws_com_nodegroup": "managed-ondemand-2022110404042617720000001b",
    "eks_amazonaws_com_nodegroup_image": "ami-01dfb5782bffd09d6",
    "eks_amazonaws_com_sourceLaunchTemplateId": "lt-0566ef61fb851d6e1",
    "eks_amazonaws_com_sourceLaunchTemplateVersion": "1",
    "failure_domain_beta_kubernetes_io_region": "us-west-2",
    "failure_domain_beta_kubernetes_io_zone": "us-west-2c",
    "instance": "ip-10-42-12-99.us-west-2.compute.internal",
    "job": "kubernetes-kubelet",
    "k8s_io_cloud_provider_aws": "ffc60533e6d069826fca0578b02694a2",
    "kubernetes_io_arch": "amd64",
    "kubernetes_io_hostname": "ip-10-42-12-99.us-west-2.compute.internal",
    "kubernetes_io_os": "linux",
    "node_kubernetes_io_instance_type": "m5.large",
    "region": "us-west-2",
    "topology_ebs_csi_aws_com_zone": "us-west-2c",
    "topology_kubernetes_io_region": "us-west-2",
    "topology_kubernetes_io_zone": "us-west-2c",
    "workshop_default": "yes"
  },
  "value": [
    1667597359,
    "1"
  ]
}
```