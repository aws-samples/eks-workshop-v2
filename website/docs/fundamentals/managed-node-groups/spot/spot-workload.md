---
title: "Running a workload on Spot"
sidebar_position: 30
---

Next, let's modify our sample retail store application to run the catalog component on the newly created Spot instances. To do so, we'll utilize Kustomize to apply a patch to the `catalog` Deployment, adding a `nodeSelector` field with `eks.amazonaws.com/capacityType: SPOT`.

```kustomization
modules/fundamentals/mng/spot/deployment/deployment.yaml
Deployment/catalog
```

Apply the Kustomize patch with the following command.

```bash
$ kubectl apply -k ~/environment/eks-workshop/modules/fundamentals/mng/spot/deployment

namespace/catalog unchanged
serviceaccount/catalog unchanged
configmap/catalog unchanged
secret/catalog-db unchanged
service/catalog unchanged
service/catalog-mysql unchanged
deployment.apps/catalog configured
statefulset.apps/catalog-mysql unchanged
```

Ensure the successful deployment of your app with the following command.

```bash
$ kubectl rollout status deployment/catalog -n catalog --timeout=5m
```

Finally, let's verify that the catalog pods are running on Spot instances. Run the following two commands.

```bash
$ kubectl get pods -l app.kubernetes.io/component=service -n catalog -o wide

NAME                       READY   STATUS    RESTARTS   AGE     IP              NODE
catalog-6bf46b9654-9klmd   1/1     Running   0          7m13s   10.42.118.208   ip-10-42-99-254.us-east-2.compute.internal
$ kubectl get nodes -l eks.amazonaws.com/capacityType=SPOT

NAME                                          STATUS   ROLES    AGE   VERSION
ip-10-42-139-140.us-east-2.compute.internal   Ready    <none>   16m   vVAR::KUBERNETES_NODE_VERSION
ip-10-42-99-254.us-east-2.compute.internal    Ready    <none>   16m   vVAR::KUBERNETES_NODE_VERSION

```

The first command tells us that the catalog pod is running on node `ip-10-42-99-254.us-east-2.compute.internal`, which we verify is a Spot instance by matching it to the output of the second command.

In this lab, you deployed a managed node group that creates Spot instances, and then modified the `catalog` deployment to run on the newly created Spot instances. Following this process, you can modify any of the running deployments in the cluster by adding the `nodeSelector` parameter, as specified in the Kustomization patch above.
