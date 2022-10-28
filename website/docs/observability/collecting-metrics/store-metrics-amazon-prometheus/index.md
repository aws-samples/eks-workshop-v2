---
title: "Storing metrics on Amazon Managed Service for Prometheus"
sidebar_position: 60
---

In this module, we will verify the ingestion of metrics into the Amazon Managed Service for Prometheus

The Amazon Managed Service for Prometheus workspace is already created for you. You should be able to see `observability` workspace on the Amazon Managed Service for Prometheus console

By running the awscurl, let's verify the successful ingestion of the metrics:

```bash 
export AMP_QUERY_ENDPOINT= https://aps-workspaces.Region.amazonaws.com/workspaces/Workspace-id/api/v1/query
awscurl -X POST --region Region --service aps "$AMP_QUERY_ENDPOINT?query=up"
```

You should be able to see the below output:
```json 
{"status":"success","data":{"resultType":"vector","result":[{"metric":{"__name__":"up","alpha_eksctl_io_cluster_name":"capstone-eks-accelerator","alpha_eksctl_io_nodegroup_name":"nodegroup","beta_kubernetes_io_arch":"amd64","beta_kubernetes_io_instance_type":"t3.small","beta_kubernetes_io_os":"linux","cluster":"capstone-eks-accelerator","eks_amazonaws_com_capacityType":"ON_DEMAND","eks_amazonaws_com_nodegroup":"nodegroup","eks_amazonaws_com_nodegroup_image"
```

