---
title: "Sample Application Setup"
weight: 30
---

Though many variables are changeable in the following steps, we recommend only changing variable values where specified. Once you have a better understanding of Kubernetes pods, deployments, and services, you can experiment with changing other values.

1. Create a namespace. A namespace allows you to group resources in Kubernetes. For more information, see [Namespaces](https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/) in the Kubernetes documentation. 

```bash
kubectl create namespace eks-sample-nth
```

2. Create a Kubernetes deployment. This sample deployment pulls a container image from a public repository and deploys three replicas (individual pods) of it to your cluster. To learn more, see [Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/) in the Kubernetes documentation.

a. Save the following contents to a file named `eks-sample-deployment.yaml`.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nlb-sample-app
  namespace: eks-sample-nth
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
        - name: nginx
          image: public.ecr.aws/nginx/nginx:1.21
          ports:
            - name: tcp
              containerPort: 80

```

b. Apply the deployment manifest to your cluster.

```bash
kubectl apply -f eks-sample-deployment.yaml
```

3. Create a service. A service allows you to access all replicas through a single IP address or name. For more information, see [Service](https://kubernetes.io/docs/concepts/services-networking/service/) in the Kubernetes documentation. Though not implemented in the sample application, if you have applications that need to interact with other AWS services, we recommend that you create Kubernetes service accounts for your pods, and associate them to AWS IAM accounts. By specifying service accounts, your pods have only the minimum permissions that you specify for them to interact with other services. For more information, see [IAM roles for service accounts](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html).

a. Save the following contents to a file named `eks-sample-service.yaml`.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nlb-sample-service
  namespace: eks-sample-nth
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-type: external
    service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: ip
    service.beta.kubernetes.io/aws-load-balancer-scheme: internet-facing
spec:
  ports:
    - port: 80
      targetPort: 80
      protocol: TCP
  type: LoadBalancer
  selector:
    app: nginx
```

b. Apply the service manifest to your cluster.

```bash
kubectl apply -f eks-sample-service.yaml
```

4. Observe the `NODE` at which the pods are currently running

```bash
kubectl get pods -n eks-sample-nth --output=wide
```

{{< output >}}
NAME                             READY   STATUS    RESTARTS   AGE   IP           NODE                                       NOMINATED NODE   READINESS GATES
nlb-sample-app-7f4678c44-hkgd9   1/1     Running   0          29m   10.0.1.140   ip-10-0-1-145.us-east-2.compute.internal   <none>           <none>
nlb-sample-app-7f4678c44-nftkj   1/1     Running   0          29m   10.0.0.70    ip-10-0-0-219.us-east-2.compute.internal   <none>           <none>
nlb-sample-app-7f4678c44-tglvj   1/1     Running   0          29m   10.0.0.177   ip-10-0-0-219.us-east-2.compute.internal   <none>           <none>

{{< /output >}}


Also, note the LoadBalander DNS as a result of following command

```bash
export NTH_LB=$(kubectl get service nlb-sample-service  \-\-output=jsonpath='{.status.loadBalancer.ingress[0].hostname}' -n eks-sample-nth)
echo $NTH_LB
```

{{% notice tip %}}
It will take several minutes for the LoadBalancer to become healthy and start passing traffic to the pods.
{{% /notice %}}

5. Test if you get a successful response code of `200` from the following command

```bash
curl -s -o /dev/null -w "%{http_code}" -I http://$NTH_LB
```